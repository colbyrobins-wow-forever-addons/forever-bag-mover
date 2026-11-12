"""Run focused addon checks using lupa: python tests/check_addon.py."""

from pathlib import Path
import logging
import sys

ROOT = Path(__file__).resolve().parents[1]
# Appended so an installed lupa (CI, Docker) wins over a local Windows build.
sys.path.append(str(ROOT / ".test-deps"))
from lupa.lua51 import LuaRuntime


def main() -> None:
    """Check saved positions, drag behavior, reset, and combat deferral."""
    runtime = LuaRuntime()
    runtime.execute('''
        frames = {}
        combat = false
        function UnitName() return 'Tester' end
        function GetRealmName() return 'Realm' end
        function IsAltKeyDown() return altDown or false end
        function InCombatLockdown() return combat end
        local methods = {}
        function methods:SetScript(name, fn) self.scripts[name] = fn end
        function methods:HookScript(name, fn) self.scripts[name] = fn end
        function methods:SetPoint(...) self.point = {...} end
        function methods:IsShown() return self.shown end
        function methods:Show()
            local wasShown = self.shown
            self.shown = true
            if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function methods:GetFrameLevel() return self.level or 1 end
        function methods:IsProtected() return self.protected or false end
        function methods:SetFrameLevel(level) self.level = level end
        function methods:Hide()
            local wasShown = self.shown
            self.shown = false
            if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function methods:GetEffectiveScale() return self.scale or 1 end
        function methods:SetScale(scale) self.scale = scale end
        function methods:GetWidth() return self.width or 200 end
        function methods:GetHeight() return self.height or 300 end
        function methods:GetRight() return self.right or 800 end
        function methods:GetTop() return self.top or 500 end
        function methods:GetBottom() return self.bottom or 504 end
        function methods:GetID() return self.id or 0 end
        function methods:CreateTexture()
            return setmetatable({scripts = {}, shown = true}, {__index = methods})
        end
        function methods:CreateFontString() return self end
        function methods:SetHeight(height) self.height = height end
        function methods:SetWidth(width) self.width = width end
        function methods:GetText() return self.text or '' end
        function methods:SetText(text) self.text = text end
        function methods:GetFont() return 'font', 10, '' end
        function methods:SetFont(path, size, flags) self.fontSize = size end
        function methods:SetAlpha(alpha) self.alpha = alpha end
        for _, name in ipairs({'SetSize', 'SetFrameStrata', 'SetMovable',
            'SetClampedToScreen', 'RegisterForDrag', 'SetAllPoints',
            'SetColorTexture', 'ClearAllPoints', 'StartMoving',
            'RegisterForClicks', 'SetHighlightTexture', 'SetTexCoord', 'AddLine',
            'StopMovingOrSizing', 'RegisterEvent', 'SetAutoFocus', 'SetMaxLetters', 'ClearFocus', 'SetTexture'}) do
            methods[name] = function() end
        end
        function CreateFrame(kind, name)
            local frame = setmetatable({scripts = {}, shown = true}, {
                __index = methods
            })
            if name then _G[name] = frame end
            table.insert(frames, frame)
            return frame
        end
        GameTooltip = CreateFrame()
        function GameTooltip:SetOwner(owner) self.owner = owner end
        function GameTooltip:IsOwned(owner) return self.owner == owner end
        table.remove(frames)
        UIParent = CreateFrame()
        UIParent.width = 1920
        UIParent.height = 1080
        ContainerFrame1 = CreateFrame()
        ContainerFrame1.GetBagID = function() return 0 end
        NUM_CONTAINER_FRAMES = 1
        DEFAULT_CHAT_FRAME = {AddMessage = function() end}
        SlashCmdList = {}
        function UpdateContainerFrameAnchors()
            ContainerFrame1:SetPoint('DEFAULT')
        end
        function hooksecurefunc(target, name, callback)
            if type(target) == 'string' then
                local original = _G[target]
                _G[target] = function(...)
                    original(...)
                    name(...)
                end
            else
                local original = target[name]
                target[name] = function(...)
                    original(...)
                    callback(...)
                end
            end
        end
    ''')
    runtime.execute((ROOT / "ForeverBagMover/Layout.lua").read_text())
    runtime.execute((ROOT / "ForeverBagMover/Presets.lua").read_text())
    runtime.execute((ROOT / "ForeverBagMover/Filters.lua").read_text())
    runtime.execute(
        (ROOT / "ForeverBagMover/ForeverBagMover.lua").read_text(),
        "ForeverBagMover",
    )
    runtime.execute('''
        ForeverBagMoverDB = {x = 600, y = 700}
        local events = frames[3]
        events.scripts.OnEvent(events, 'ADDON_LOADED', 'ForeverBagMover')
        local handle = frames[4]
        assert(not handle:IsShown())
        assert(handle.toggle:IsShown() and handle.toggle.shackle.height == 7)
        assert(handle.toggle.point[1] == 'TOPRIGHT' and handle.toggle.point[2] == ContainerFrame1)
        assert(handle.toggle.point[4] == -28 and handle.toggle.point[5] == -2)
        assert(not handle.filter:IsShown(), 'Hide filter when search UI is unavailable')
        BagItemSearchBox = CreateFrame()
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(handle.filter:IsShown() and handle.filter.point[1] == 'RIGHT')
        assert(handle.filter.point[2] == BagItemSearchBox)
        assert(handle.filter.point[3] == 'LEFT' and handle.filter.point[4] == -4)
        handle.filter.scripts.OnClick(handle.filter)
        local menu = handle.filter.menu
        assert(menu:IsShown() and #menu.entries == 8)
        for index = 1, 4 do
            menu.entries[index].scripts.OnClick()
            assert(BagItemSearchBox:GetText() == ForeverBagMoverFilters.options[index].query)
            assert(not menu:IsShown())
        end
        ContainerFrame1.SearchBox = CreateFrame()
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(handle.filter.point[2] == ContainerFrame1.SearchBox)
        menu.entries[2].scripts.OnClick()
        assert(ContainerFrame1.SearchBox:GetText() == 'food')
        ContainerFrame1.SearchBox = nil
        menu.entries[1].scripts.OnClick()
        BagItemSearchBox = nil
        menu.entries[2].scripts.OnClick() -- Missing search UI must fail gracefully.
        assert(ForeverBagMoverFilters.selected == 1)
        ContainerFrame1:Hide()
        assert(not handle.toggle:IsShown())
        assert(not handle.filter:IsShown())
        ContainerFrame1:Show()
        assert(handle.toggle:IsShown(), 'Reopening backpack must restore its toggle without bag updates')
        assert(ForeverBagMoverDB.positions.bag0.x == 600)
        assert(ForeverBagMoverDB.positions.combined.x == 600)
        handle.scripts.OnDragStart(handle)
        assert(not handle.dragging)
        handle.toggle.scripts.OnEnter(handle.toggle)
        assert(GameTooltip.text == 'Unlock bag movement')
        handle.toggle.scripts.OnClick()
        handle.toggle.scripts.OnEnter(handle.toggle)
        assert(GameTooltip.text == 'Save and lock bags')
        handle.toggle.scripts.OnLeave()
        assert(not GameTooltip:IsShown())
        assert(handle.toggle.shackle.height == 3)
        assert(handle:IsShown() and ForeverBagMoverArrangePanel:IsShown())
        handle.right = 848
        handle.top = 696
        handle.scripts.OnDragStart(handle)
        handle.scripts.OnUpdate(handle)
        handle.scripts.OnDragStop(handle)
        assert(ContainerFrame1.point[4] == 900)
        assert(ForeverBagMoverDB.positions.bag0.x == 600, 'Draft must not save early')
        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverCancel.scripts.OnClick()
        assert(ContainerFrame1.point[4] == 600)
        assert(not handle:IsShown() and not ForeverBagMoverArrangePanel:IsShown())
        SlashCmdList.FOREVERBAGMOVER('')
        handle.scripts.OnDragStart(handle)
        handle.scripts.OnDragStop(handle)
        handle.toggle.scripts.OnClick()
        assert(handle.toggle:IsShown() and handle.toggle.shackle.height == 7)
        assert(ForeverBagMoverDB.positions.bag0.x == 900)
        assert(ForeverBagMoverDB.positions.combined.x == 600)
        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverReset.scripts.OnClick()
        assert(ContainerFrame1.point[4] == 800, 'Reset pins the primary bag where Blizzard placed it')
        ForeverBagMoverCancel.scripts.OnClick()
        assert(ContainerFrame1.point[4] == 900)
        SlashCmdList.FOREVERBAGMOVER('')
        combat = true
        events.scripts.OnEvent(events, 'PLAYER_REGEN_DISABLED')
        ContainerFrame1:Hide()
        ContainerFrame1:SetPoint('DEFAULT')
        ContainerFrame1:Show()
        UpdateContainerFrameAnchors()
        assert(ContainerFrame1.point[4] == 900, 'Saved position must survive combat bag layout')
        handle.scripts.OnDragStart(handle)
        assert(not handle.dragging, 'Combat must still block user dragging')
        ContainerFrame1.protected = true
        ContainerFrame1:SetPoint('PROTECTED_DEFAULT')
        assert(ContainerFrame1.point[1] == 'PROTECTED_DEFAULT')
        ContainerFrame1.protected = false
        assert(not handle:IsShown() and not ForeverBagMoverArrangePanel:IsShown())
        handle.toggle.scripts.OnClick()
        assert(not handle.toggle:IsShown())
        assert(not handle.filter:IsShown())
        SlashCmdList.FOREVERBAGMOVER('done')
        combat = false
        events.scripts.OnEvent(events, 'PLAYER_REGEN_ENABLED')
        assert(handle:IsShown() and ForeverBagMoverArrangePanel:IsShown())

        ContainerFrame2 = CreateFrame()
        ContainerFrame2.id = 1
        NUM_CONTAINER_FRAMES = 2
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        local second = frames[#frames - 3]
        assert(second:IsShown() and not second.toggle:IsShown())
        handle.toggle.scripts.OnClick()
        assert(not handle:IsShown() and not second:IsShown())
        assert(handle.toggle:IsShown() and not second.toggle:IsShown())
        handle.toggle.scripts.OnClick()
        assert(handle:IsShown() and second:IsShown())
        assert(handle.toggle.shackle.height == 3 and not second.toggle:IsShown())
        second.right = 1170
        second.top = 796
        second.scripts.OnDragStart(second)
        second.scripts.OnDragStop(second)
        assert(ForeverBagMoverDB.positions.bag1 == nil)
        assert(ContainerFrame1.point[4] == 900)
        SlashCmdList.FOREVERBAGMOVER('done')
        assert(ForeverBagMoverDB.positions.bag1.x == 1200)
        ContainerFrame2.id = 2
        ContainerFrame2:SetPoint('DEFAULT')
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(ContainerFrame2.point[1] == 'DEFAULT')
        ContainerFrame2.id = 1
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(ContainerFrame2.point[4] == 1200)
        SlashCmdList.FOREVERBAGMOVER('')
        ContainerFrame2.id = -1
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(not second:IsShown())
        ContainerFrame2.id = 1
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        second.scripts.OnDragStart(second)
        ContainerFrame2.id = 3
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(not second.dragging)
        SlashCmdList.FOREVERBAGMOVER('done')
        assert(ForeverBagMoverDB.positions.bag3 == nil)
        SlashCmdList.FOREVERBAGMOVER('reset')
        assert(ForeverBagMoverDB.positions.bag0.x == 900)
        ForeverBagMoverDone.scripts.OnClick()
        assert(ForeverBagMoverDB.positions.bag0.x == 800 and ForeverBagMoverDB.positions.bag1 == nil)
    ''')
    runtime.execute('''
        local geometry = ForeverBagMoverLayout
        local bags = {
            {key = 'bag0', x = 400, y = 600, w = 200, h = 300},
            {key = 'bag1', x = 608, y = 600, w = 200, h = 200},
            {key = 'bag2', x = 816, y = 600, w = 100, h = 250},
        }
        local row = geometry.Arrange(bags, 'row', 8, 1920, 1052)
        assert(row.bag1.x - 200 - row.bag0.x == 8)
        assert(row.bag0.y == row.bag2.y)
        local column = geometry.Arrange(bags, 'column', 8, 1920, 1052)
        assert(column.bag1.y == column.bag0.y - 300 - 8)
        local grid = geometry.Arrange(bags, 'grid', 8, 1920, 1052)
        assert(grid.bag2.y == grid.bag0.y - 300 - 8)
        assert(geometry.Arrange(bags, 'row', 8, 300, 400) == nil)
        local moved = geometry.Translate(bags, -1000, 1000, 1920, 1052)
        assert(moved.bag0.x == 200 and moved.bag0.y == 1052)
        assert(moved.bag1.x - moved.bag0.x == 208)
        assert(moved.bag2.y - moved.bag0.y == 0)
        local x, y, gx, gy = geometry.Snap(
            {key = 'bag0', x = 405, y = 596, w = 200, h = 300},
            bags, 1920, 1052, 8)
        assert(x == 400 and y == 600 and gx ~= nil and gy ~= nil)
        x, y = geometry.Snap({key = 'only', x = 1915, y = 1048, w = 200, h = 300},
            {}, 1920, 1052, 8)
        assert(x == 1920 and y == 1052)

        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverRow.scripts.OnClick()
        assert(ForeverBagMoverDB.positions.bag0.x == 800, 'Layout must remain a preview')
        assert(ContainerFrame1.point[4] == 210)
        ForeverBagMoverCancel.scripts.OnClick()
        assert(ForeverBagMoverDB.positions.bag0.x == 800)
        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverGrid.scripts.OnClick()
        ForeverBagMoverGroup.scripts.OnClick(ForeverBagMoverGroup)
        local handle = frames[4]
        local firstX, firstY = ContainerFrame1.point[4], ContainerFrame1.point[5]
        local secondX, secondY = ContainerFrame2.point[4], ContainerFrame2.point[5]
        handle.right = firstX - 52 + 40
        handle.top = firstY - 4 - 50
        handle.scripts.OnDragStart(handle)
        handle.scripts.OnUpdate(handle)
        handle.scripts.OnDragStop(handle)
        assert(ContainerFrame1.point[4] == firstX + 40)
        assert(ContainerFrame2.point[4] == secondX + 40)
        assert(ContainerFrame2.point[5] == secondY - 50)
        ForeverBagMoverDone.scripts.OnClick()
        assert(ForeverBagMoverDB.positions.bag0.x == firstX + 40)
        SlashCmdList.FOREVERBAGMOVER('')
        combat = true
        local previousX = ContainerFrame1.point[4]
        ForeverBagMoverRow.scripts.OnClick()
        assert(ContainerFrame1.point[4] == previousX)
        combat = false
        ForeverBagMoverCancel.scripts.OnClick()
        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverGroup.scripts.OnClick(ForeverBagMoverGroup)
        altDown = true
        handle.right, handle.top = 1915 - 52, 696
        handle.scripts.OnDragStart(handle)
        handle.scripts.OnUpdate(handle)
        assert(ContainerFrame1.point[4] == 1915, 'Alt must bypass the screen-edge snap')
        altDown = false
        handle.scripts.OnUpdate(handle)
        assert(ContainerFrame1.point[4] == 1920, 'Releasing Alt must restore snapping')
        handle.scripts.OnDragStop(handle)
        ForeverBagMoverCancel.scripts.OnClick()
    ''')
    runtime.execute('''
        local presets = ForeverBagMoverPresets
        assert(presets.Name('  Banking  ') == 'Banking')
        assert(presets.Name('   ') == nil)
        assert(presets.Name('|bad') == nil)
        local source = {bag0 = {x = 800, y = 600}, combined = {x = 900, y = 700}}
        local snapshot = presets.Capture(source, 1600, 1000)
        source.bag0.x = 1
        local restored = presets.Restore(snapshot, 800, 500)
        assert(restored.bag0.x == 400 and restored.bag0.y == 300)
        restored.bag0.x = 0
        assert(snapshot.positions.bag0.x == 0.5)
        assert(presets.Restore({version = 2}, 800, 500) == nil)
        assert(presets.Restore({version = 1, positions = {bag0 = {x = 'oops', y = 1}}}, 800, 500) == nil)

        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverRow.scripts.OnClick()
        local previous = ForeverBagMoverDB.positions.bag0.x
        ForeverBagMoverPresetName:SetText('Questing')
        ForeverBagMoverSavePreset.scripts.OnClick()
        assert(ForeverBagMoverSharedDB.presets.Questing.version == 1)
        assert(ForeverBagMoverDB.positions.bag0.x == previous)
        ForeverBagMoverCancel.scripts.OnClick()
        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverLoadPreset.scripts.OnClick()
        assert(ContainerFrame1.point[4] == 210)
        assert(ForeverBagMoverDB.positions.bag0.x == previous)
        ForeverBagMoverCancel.scripts.OnClick()
        assert(ForeverBagMoverDB.positions.bag0.x == previous)

        ForeverBagMoverSharedDB.characters['Alt - OtherRealm'] = snapshot
        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverCharacterSelect.scripts.OnClick(ForeverBagMoverCharacterSelect)
        ForeverBagMoverCopyCharacter.scripts.OnClick()
        assert(ContainerFrame1.point[4] == 960)
        assert(ForeverBagMoverDB.positions.bag0.x == previous)
        ForeverBagMoverDone.scripts.OnClick()
        assert(ForeverBagMoverDB.positions.bag0.x == 960)
        assert(ForeverBagMoverSharedDB.characters['Tester - Realm'].positions.bag0.x == 0.5)
        assert(ForeverBagMoverSharedDB.characters['Alt - OtherRealm'].positions.bag0.x == 0.5)
        SlashCmdList.FOREVERBAGMOVER('')
        combat = true
        ForeverBagMoverPresetName:SetText('Blocked')
        ForeverBagMoverSavePreset.scripts.OnClick()
        assert(ForeverBagMoverSharedDB.presets.Blocked == nil)
        ForeverBagMoverLoadPreset.scripts.OnClick()
        assert(ContainerFrame1.point[4] == 960)
        combat = false
        ForeverBagMoverCancel.scripts.OnClick()
    ''')
    runtime.execute('''
        local filters = ForeverBagMoverFilters
        local info = {itemID = 1, quality = 0}
        assert(filters.Matches('junk', info))
        assert(not filters.Matches('junk', {itemID = 2, quality = 1}))
        assert(filters.Matches('quest', info, 12))
        assert(filters.Matches('quest', info, 0, '', {questID = 42}))
        assert(not filters.Matches('quest', info, 0, '', {}))
        assert(filters.Matches('reagents', info, 7))
        assert(filters.Matches('reagents', info, 5))
        assert(not filters.Matches('reagents', info, 2))
        assert(filters.Matches('equipment', info, 4, 'INVTYPE_HEAD'))
        assert(not filters.Matches('equipment', info, 4, ''))
        assert(not filters.Matches('junk', nil))
        local button = CreateFrame()
        button.GetBagID = function() return 0 end
        button.SetMatchesSearch = function() error('Calling Blizzard SetMatchesSearch taints item use') end
        ContainerFrame1.Items = {button}
        C_Container = {GetContainerItemInfo = function() return info end}
        filters.selected = 1
        filters.Apply(ContainerFrame1, 0)
        assert(not filters.IsDimmed(button), 'All items must not dim or touch buttons')
        filters.selected = 8
        filters.Apply(ContainerFrame1, 0)
        assert(not filters.IsDimmed(button), 'Junk must stay undimmed')
        info.quality = 1
        filters.Apply(ContainerFrame1, 0)
        assert(filters.IsDimmed(button), 'Non-junk must be dimmed')
        filters.selected = 1
        filters.Apply(ContainerFrame1, 0)
        assert(not filters.IsDimmed(button), 'All items must clear dimming')
    ''')
    runtime.execute("""
        cursorX, cursorY = 800, 200
        function GetCursorPosition() return cursorX, cursorY end
        SlashCmdList.FOREVERBAGMOVER('')
        local grip = frames[4].resize
        assert(grip:IsShown())
        grip.scripts.OnDragStart()
        cursorX, cursorY = 840, 140
        grip.scripts.OnUpdate()
        assert(ContainerFrame1.scale == 1.2)
        assert(ContainerFrame2.scale == 1)
        grip.scripts.OnDragStop()
        ForeverBagMoverCancel.scripts.OnClick()
        assert(ContainerFrame1.scale == 1)
        SlashCmdList.FOREVERBAGMOVER('')
        grip.scripts.OnDragStart()
        cursorX, cursorY = 2000, -2000
        grip.scripts.OnUpdate()
        assert(ContainerFrame1.scale == 1.5)
        ForeverBagMoverDone.scripts.OnClick()
        assert(ForeverBagMoverDB.scales.bag0 == 150)
        assert(not grip:IsShown() and grip.origin == nil)
        SlashCmdList.FOREVERBAGMOVER('')
        grip.scripts.OnDragStart()
        combat = true
        cursorX = 0
        grip.scripts.OnUpdate()
        assert(grip.origin == nil and ContainerFrame1.scale == 1.5)
        combat = false
        ForeverBagMoverCancel.scripts.OnClick()
    """)
    runtime.execute("""
        -- Free move: drag any time outside arrange mode; drops save directly.
        local handle = frames[4]
        local events = frames[3]
        local toggle = handle.toggle
        assert(ForeverBagMoverDB.freeMove == false, 'Free move defaults off')
        assert(not handle:IsShown())
        assert(toggle.lockParts[1]:IsShown() and not toggle.settingsParts[1]:IsShown())
        SlashCmdList.FOREVERBAGMOVER('free on')
        assert(ForeverBagMoverDB.freeMove == true)
        assert(handle:IsShown() and handle.alpha == 0, 'Free-move handle is invisible until hovered')
        assert(not handle.resize:IsShown(), 'Resize stays limited to arrange mode')
        assert(not ForeverBagMoverArrangePanel:IsShown())
        assert(not toggle.lockParts[1]:IsShown() and toggle.settingsParts[1]:IsShown())
        toggle.scripts.OnEnter(toggle)
        assert(GameTooltip.text == 'Arrange bags (presets, layouts, resize)')
        toggle.scripts.OnLeave()
        handle.scripts.OnEnter(handle)
        assert(handle.alpha == 0.6)
        handle.scripts.OnLeave(handle)
        assert(handle.alpha == 0)

        altDown = true
        handle.right, handle.top = 1000, 600
        handle.scripts.OnDragStart(handle)
        assert(handle.dragging and handle.alpha == 0.6)
        handle.scripts.OnUpdate(handle)
        handle.scripts.OnDragStop(handle)
        altDown = false
        assert(ForeverBagMoverDB.positions.bag0.x == 1078, 'Free-move drop saves immediately')
        assert(ForeverBagMoverDB.positions.bag0.y == 604)
        assert(ContainerFrame1.point[4] == 1078 / 1.5)
        assert(ForeverBagMoverSharedDB.characters['Tester - Realm'].positions.bag0.x == 1078 / 1920)
        assert(handle.alpha == 0 and not ForeverBagMoverArrangePanel:IsShown())

        combat = true
        events.scripts.OnEvent(events, 'PLAYER_REGEN_DISABLED')
        assert(not handle:IsShown())
        handle.scripts.OnDragStart(handle)
        assert(not handle.dragging, 'Combat blocks free-move dragging')
        SlashCmdList.FOREVERBAGMOVER('free off')
        assert(ForeverBagMoverDB.freeMove == true, 'Setting cannot change in combat')
        combat = false
        events.scripts.OnEvent(events, 'PLAYER_REGEN_ENABLED')
        assert(handle:IsShown())

        toggle.scripts.OnClick()
        assert(ForeverBagMoverArrangePanel:IsShown() and handle.alpha == 1)
        assert(handle.resize:IsShown())
        assert(ForeverBagMoverFreeMove.text == 'Always movable: On')
        toggle.scripts.OnEnter(toggle)
        assert(GameTooltip.text == 'Save and close arrange panel')
        toggle.scripts.OnLeave()
        altDown = true
        handle.right, handle.top = 900, 600
        handle.scripts.OnDragStart(handle)
        handle.scripts.OnDragStop(handle)
        altDown = false
        assert(ForeverBagMoverDB.positions.bag0.x == 1078, 'Arrange mode still drafts')
        ForeverBagMoverCancel.scripts.OnClick()
        assert(ForeverBagMoverDB.freeMove == true, 'Cancel keeps the free-move setting')
        assert(ContainerFrame1.point[4] == 1078 / 1.5)
        assert(handle:IsShown() and handle.alpha == 0)

        SlashCmdList.FOREVERBAGMOVER('')
        ForeverBagMoverFreeMove.scripts.OnClick()
        assert(ForeverBagMoverDB.freeMove == false)
        assert(ForeverBagMoverFreeMove.text == 'Always movable: Off')
        ForeverBagMoverCancel.scripts.OnClick()
        assert(not handle:IsShown())
        handle.scripts.OnDragStart(handle)
        assert(not handle.dragging, 'Locked bags cannot be dragged')
        assert(toggle.lockParts[1]:IsShown() and not toggle.settingsParts[1]:IsShown())
        SlashCmdList.FOREVERBAGMOVER('free')
        assert(ForeverBagMoverDB.freeMove == true, 'Bare /fbm free toggles')
        SlashCmdList.FOREVERBAGMOVER('free')
        assert(ForeverBagMoverDB.freeMove == false)

        ForeverBagMoverDB.freeMove = 'yes'
        events.scripts.OnEvent(events, 'ADDON_LOADED', 'ForeverBagMover')
        assert(ForeverBagMoverDB.freeMove == false, 'Invalid saved value resets to off')
        ForeverBagMoverDB.freeMove = true
        events.scripts.OnEvent(events, 'ADDON_LOADED', 'ForeverBagMover')
        assert(ForeverBagMoverDB.freeMove == true and handle:IsShown())

        BagItemSearchBox = CreateFrame()
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(ForeverBagMoverDB.hideButtons == false)
        assert(handle.toggle:IsShown() and handle.filter:IsShown())
        handle.filter.scripts.OnClick(handle.filter)
        SlashCmdList.FOREVERBAGMOVER('buttons hide')
        assert(ForeverBagMoverDB.hideButtons == true)
        assert(not handle.toggle:IsShown() and not handle.filter:IsShown())
        assert(not handle.filter.menu:IsShown(), 'Hiding closes the filter menu')
        ContainerFrame1:Hide()
        ContainerFrame1:Show()
        events.scripts.OnEvent(events, 'ADDON_LOADED', 'ForeverBagMover')
        assert(ForeverBagMoverDB.hideButtons == true, 'Saved preference survives initialization')
        assert(not handle.toggle:IsShown() and not handle.filter:IsShown())
        SlashCmdList.FOREVERBAGMOVER('')
        assert(ForeverBagMoverArrangePanel:IsShown(), 'Slash command remains accessible')
        SlashCmdList.FOREVERBAGMOVER('cancel')
        combat = true
        SlashCmdList.FOREVERBAGMOVER('buttons show')
        assert(ForeverBagMoverDB.hideButtons == true, 'Combat blocks visibility changes')
        combat = false
        events.scripts.OnEvent(events, 'PLAYER_REGEN_ENABLED')
        assert(not handle.toggle:IsShown() and not handle.filter:IsShown())
        SlashCmdList.FOREVERBAGMOVER('buttons show')
        assert(handle.toggle:IsShown() and handle.filter:IsShown())
        ForeverBagMoverDB.hideButtons = 'yes'
        events.scripts.OnEvent(events, 'ADDON_LOADED', 'ForeverBagMover')
        assert(ForeverBagMoverDB.hideButtons == false, 'Invalid preference defaults to visible')
        SlashCmdList.FOREVERBAGMOVER('buttons show')
        SlashCmdList.FOREVERBAGMOVER('')
        local visibility = ForeverBagMoverButtonsVisibility
        assert(visibility.text == 'Bag buttons: Shown')
        visibility.scripts.OnClick()
        assert(ForeverBagMoverDB.hideButtons and visibility.text == 'Bag buttons: Hidden')
        assert(not handle.toggle:IsShown() and not handle.filter:IsShown())
        SlashCmdList.FOREVERBAGMOVER('cancel')
        assert(ForeverBagMoverDB.hideButtons, 'Visibility saves immediately, including Cancel')
        SlashCmdList.FOREVERBAGMOVER('')
        assert(visibility.text == 'Bag buttons: Hidden')
        combat = true
        visibility.scripts.OnClick()
        assert(ForeverBagMoverDB.hideButtons, 'Menu setting is blocked in combat')
        combat = false
        SlashCmdList.FOREVERBAGMOVER('buttons show')
        assert(visibility.text == 'Bag buttons: Shown', 'Slash command updates the menu')
        visibility.scripts.OnClick()
        visibility.scripts.OnClick()
        assert(not ForeverBagMoverDB.hideButtons and handle.toggle:IsShown())
        SlashCmdList.FOREVERBAGMOVER('done')
        assert(ForeverBagMoverMinimapButton == nil, 'Missing minimap must be harmless')
        Minimap = CreateFrame()
        events.scripts.OnEvent(events, 'PLAYER_LOGIN')
        local launcher = ForeverBagMoverMinimapButton
        assert(launcher and launcher.point[2] == Minimap)
        local edge = (Minimap:GetWidth() / 2 + 10) * math.cos(math.rad(45))
        assert(math.abs(launcher.point[4] + edge) < 0.01
            and math.abs(launcher.point[5] + edge) < 0.01,
            'Launcher sits just outside the lower-left minimap edge')
        local iconPoint = launcher.icon.point
        assert(iconPoint[1] == 'TOPLEFT' and iconPoint[2] == launcher
            and iconPoint[4] == 7 and iconPoint[5] == -6,
            'Icon is centered inside the tracking-border ring')
        local geometry = ForeverBagMoverLayout
        assert(ForeverBagMoverDB.minimapAngle == 225, 'Launcher angle defaults to lower-left')
        assert(geometry.ValidMinimapAngle('bad') == 225 and geometry.ValidMinimapAngle(360) == 225
            and geometry.ValidMinimapAngle(0 / 0) == 225 and geometry.ValidMinimapAngle(90) == 90)
        assert(math.abs(geometry.MinimapAngle(-1, -1) - 225) < 0.01
            and math.abs(geometry.MinimapAngle(1, 0)) < 0.01
            and math.abs(geometry.MinimapAngle(0, -1) - 270) < 0.01)
        function Minimap:GetCenter() return 500, 400 end
        Minimap.scale = 2
        cursorX, cursorY = 1000, 1200
        launcher.scripts.OnDragStart(launcher)
        launcher.scripts.OnUpdate(launcher)
        local radius = Minimap:GetWidth() / 2 + 10
        assert(math.abs(ForeverBagMoverDB.minimapAngle - 90) < 0.01, 'Dragging follows the cursor angle')
        assert(math.abs(launcher.point[4]) < 0.01 and math.abs(launcher.point[5] - radius) < 0.01,
            'Dragged launcher stays on the minimap edge')
        launcher.scripts.OnDragStop(launcher)
        assert(launcher.scripts.OnUpdate == nil, 'Releasing the drag stops tracking')
        Minimap.scale = nil
        local frameCount = #frames
        events.scripts.OnEvent(events, 'BAG_UPDATE_DELAYED')
        assert(#frames == frameCount, 'Events must not duplicate the minimap button')
        SlashCmdList.FOREVERBAGMOVER('buttons hide')
        assert(launcher:IsShown(), 'Bag button preference must leave the launcher accessible')
        launcher.scripts.OnEnter(launcher)
        assert(GameTooltip.text == 'Forever Bag Mover' and GameTooltip:IsShown())
        launcher.scripts.OnLeave()
        assert(not GameTooltip:IsShown())
        launcher.scripts.OnClick()
        assert(ForeverBagMoverArrangePanel:IsShown(), 'Minimap click opens settings')
        launcher.scripts.OnClick()
        assert(ForeverBagMoverArrangePanel:IsShown(), 'Repeated click preserves the draft')
        SlashCmdList.FOREVERBAGMOVER('cancel')
        combat = true
        launcher.scripts.OnClick()
        assert(not ForeverBagMoverArrangePanel:IsShown(), 'Combat blocks minimap settings access')
        combat = false
        launcher.scripts.OnClick()
        assert(ForeverBagMoverArrangePanel:IsShown())
        assert(ForeverBagMoverDB.hideMinimap == false, 'Minimap icon defaults to shown')
        local minimapToggle = ForeverBagMoverMinimapVisibility
        assert(minimapToggle.text == 'Minimap icon: Shown')
        SlashCmdList.FOREVERBAGMOVER('minimap hide')
        assert(ForeverBagMoverDB.hideMinimap and not launcher:IsShown(), 'Slash command hides the icon')
        assert(minimapToggle.text == 'Minimap icon: Hidden', 'Slash command updates the menu')
        combat = true
        minimapToggle.scripts.OnClick()
        combat = false
        assert(not ForeverBagMoverDB.hideMinimap and launcher:IsShown(),
            'Menu toggle restores the icon, including in combat')
        assert(minimapToggle.text == 'Minimap icon: Shown')
        minimapToggle.scripts.OnClick()
        SlashCmdList.FOREVERBAGMOVER('cancel')
        assert(ForeverBagMoverDB.hideMinimap and not launcher:IsShown(), 'Visibility saves immediately, including Cancel')
        SlashCmdList.FOREVERBAGMOVER('minimap show')
        assert(launcher:IsShown())
        SlashCmdList.FOREVERBAGMOVER('')
        SlashCmdList.FOREVERBAGMOVER('done')
    """)
    logging.basicConfig(level=logging.INFO)
    logging.info("Arrange-mode checks passed (mocked WoW APIs).")


if __name__ == "__main__":
    main()
