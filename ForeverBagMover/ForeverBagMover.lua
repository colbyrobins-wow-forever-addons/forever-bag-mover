local addonName = ...
local events = CreateFrame("Frame")
local handles = {}
local applying = false
local ready = false
local draftPositions
local draftScale
local draftScales
local panel
local snapping = true
local moveGroup = false
local spacing = 8
local guides = {}
local Refresh
local UpdateHandleGeometry
local BeginArrange
local FinishArrange

local function Message(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff80d0ffForever Bag Mover:|r " .. text)
end

local function CharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then return nil end
    return name .. " - " .. realm
end

local function RememberCharacter()
    local key = CharacterKey()
    if ready and key then
        ForeverBagMoverSharedDB.characters[key] = ForeverBagMoverPresets.Capture(
            ForeverBagMoverDB.positions, UIParent:GetWidth(), UIParent:GetHeight())
    end
end

local function AddControlBorder(control)
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local line = control:CreateTexture(nil, "BORDER")
        line:SetColorTexture(1, 0.78, 0.3, 0.95)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetHeight(1)
            line:SetPoint(edge .. "LEFT", control, edge .. "LEFT")
            line:SetPoint(edge .. "RIGHT", control, edge .. "RIGHT")
        else
            line:SetWidth(1)
            line:SetPoint("TOP" .. edge, control, "TOP" .. edge)
            line:SetPoint("BOTTOM" .. edge, control, "BOTTOM" .. edge)
        end
    end
end

local function GetBagKey(frame)
    if frame == ContainerFrameCombinedBags then
        return "combined"
    end
    local id = frame.GetBagID and frame:GetBagID() or frame:GetID()
    if type(id) == "number" and id >= 0 and id <= (NUM_TOTAL_BAG_FRAMES or 5) then
        return "bag" .. id
    end
end

local function Positions()
    return draftPositions or ForeverBagMoverDB.positions
end

-- Free move lets bags be dragged without arrange mode; drops save directly.
local function FreeMove()
    return ready and ForeverBagMoverDB.freeMove == true
end

local function CanDrag()
    return draftPositions ~= nil or FreeMove()
end

local function CopyPositions(source)
    local result = {}
    for key, position in pairs(source) do
        if type(position) == "table" then
            result[key] = {x = position.x, y = position.y}
        end
    end
    return result
end

local function HasPosition(db)
    return type(db) == "table" and type(db.x) == "number" and type(db.y) == "number"
        and db.x == db.x and db.y == db.y
        and math.abs(db.x) < math.huge and math.abs(db.y) < math.huge
end

local function BagScale(key)
    local overrides = draftScales or ForeverBagMoverDB.scales
    return overrides[key] or draftScale or ForeverBagMoverDB.scale
end

local function ApplyPosition(frame)
    if applying or not ready then return end
    -- Blizzard can relayout bags when opened in combat. Restore ordinary bag
    -- frames, but leave protected frames alone until PLAYER_REGEN_ENABLED.
    if InCombatLockdown() and (not frame.IsProtected or frame:IsProtected()) then return end
    local key = GetBagKey(frame)
    if key and frame:IsShown() and not InCombatLockdown() then
        applying = true
        frame:SetScale(BagScale(key) / 100)
        applying = false
    end
    local position = key and Positions()[key]
    if not frame:IsShown() or not HasPosition(position) then
        return
    end
    applying = true
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width = frame:GetWidth() * scale
    local height = frame:GetHeight() * scale
    local x = math.min(UIParent:GetWidth(), math.max(width, position.x))
    local y = math.min(UIParent:GetHeight() - 28, math.max(height, position.y))
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    applying = false
end

local function VisibleBags()
    local bags = {}
    for frame in pairs(handles) do
        local key = GetBagKey(frame)
        if key and frame:IsShown() then
            local position = Positions()[key]
            local right, top = frame:GetRight(), frame:GetTop()
            if HasPosition(position) or (right and top) then
                local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
                table.insert(bags, {key = key, frame = frame,
                    x = HasPosition(position) and position.x or right * scale,
                    y = HasPosition(position) and position.y or top * scale,
                    w = frame:GetWidth() * scale, h = frame:GetHeight() * scale})
            end
        end
    end
    table.sort(bags, function(a, b) return a.key < b.key end)
    return bags
end

local function ShowGuides(x, y)
    for index, coordinate in ipairs({x or false, y or false}) do
        local guide = guides[index]
        if coordinate then
            if not guide then
                guide = CreateFrame("Frame", nil, UIParent)
                guide:SetFrameStrata("TOOLTIP")
                local texture = guide:CreateTexture(nil, "OVERLAY")
                texture:SetAllPoints()
                texture:SetColorTexture(0.2, 0.9, 1, 0.8)
                guides[index] = guide
            end
            guide:ClearAllPoints()
            guide:SetSize(index == 1 and 1 or UIParent:GetWidth(),
                index == 1 and UIParent:GetHeight() or 1)
            guide:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                index == 1 and coordinate or 0, index == 2 and coordinate or 0)
            guide:Show()
        elseif guide then guide:Hide() end
    end
end

local function Attach(frame)
    if not frame or handles[frame] then
        return
    end
    local handle = CreateFrame("Button", nil, UIParent)
    handles[frame] = handle
    local toggle = CreateFrame("Button", nil, frame)
    handle.toggle = toggle
    toggle:SetSize(20, 20)
    toggle:SetFrameStrata("DIALOG")
    toggle:SetFrameLevel(frame:GetFrameLevel() + 20)
    toggle:ClearAllPoints()
    toggle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -2)
    local backdrop = toggle:CreateTexture(nil, "BACKGROUND")
    backdrop:SetAllPoints()
    backdrop:SetColorTexture(0.035, 0.025, 0.015, 0.95)
    AddControlBorder(toggle)
    -- Code-drawn padlock avoids relying on client-specific icon atlases.
    local function Part(width, height, x, y, r, g, b)
        local texture = toggle:CreateTexture(nil, "ARTWORK")
        texture:SetSize(width, height)
        texture:SetPoint("TOPLEFT", toggle, "TOPLEFT", x, y)
        texture:SetColorTexture(r, g, b, 1)
        return texture
    end
    toggle.lockParts = {
        Part(14, 10, 3, -8, 0.65, 0.40, 0.08),
        Part(12, 8, 4, -9, 1, 0.80, 0.30),
        Part(2, 4, 9, -11, 0.15, 0.10, 0.04),
        Part(10, 2, 5, -2, 1, 0.93, 0.65),
        Part(2, 7, 13, -2, 1, 0.93, 0.65),
        Part(2, 7, 5, -2, 1, 0.93, 0.65),
    }
    toggle.shackle = toggle.lockParts[6]
    -- With free move on, a sliders icon opens the arrange panel instead.
    toggle.settingsParts = {}
    for _, bar in ipairs({{-4, 9}, {-9, 4}, {-14, 11}}) do
        table.insert(toggle.settingsParts, Part(14, 2, 3, bar[1], 1, 0.80, 0.30))
        table.insert(toggle.settingsParts, Part(4, 4, bar[2] - 1, bar[1] + 1, 1, 0.93, 0.65))
    end
    for _, texture in ipairs(toggle.settingsParts) do texture:Hide() end
    local hover = toggle:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 0.85, 0.5, 0.35)
    toggle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if FreeMove() then
            GameTooltip:SetText(draftPositions and "Save and close arrange panel"
                or "Arrange bags (presets, layouts, resize)")
        else
            GameTooltip:SetText(draftPositions and "Save and lock bags" or "Unlock bag movement")
        end
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    toggle:SetScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    toggle:SetScript("OnClick", function()
        local key = GetBagKey(frame)
        if key ~= "bag0" and key ~= "combined" then return end
        GameTooltip:Hide()
        if draftPositions then FinishArrange(true) else BeginArrange() end
    end)
    toggle:Hide()
    local filter = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    handle.filter = filter
    filter:SetSize(28, 26)
    filter:SetText("")
    filter:SetFrameStrata("DIALOG")
    -- A small gold funnel distinguishes filtering from the cleanup broom.
    for _, part in ipairs({
        {16, 2, 0, 5}, {12, 2, 0, 3}, {8, 2, 0, 1},
        {4, 6, 0, -3}, {2, 2, 1, -7},
    }) do
        local texture = filter:CreateTexture(nil, "OVERLAY")
        texture:SetSize(part[1], part[2])
        texture:SetPoint("CENTER", filter, "CENTER", part[3], part[4])
        texture:SetColorTexture(1, 0.82, 0.3, 1)
    end
    filter:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Bag filter: " .. ForeverBagMoverFilters.options[ForeverBagMoverFilters.selected].label)
        GameTooltip:Show()
    end)
    filter:SetScript("OnLeave", function() GameTooltip:Hide() end)
    filter:SetScript("OnHide", function(self)
        if self.menu then self.menu:Hide() end
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    filter:SetScript("OnClick", function(self)
        local key = GetBagKey(frame)
        if InCombatLockdown() or (key ~= "bag0" and key ~= "combined") then return end
        GameTooltip:Hide()
        if not self.menu then
            local menu = CreateFrame("Frame", nil, self)
            self.menu = menu
            menu:SetSize(150, 200)
            menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            menu:SetFrameStrata("DIALOG")
            menu:SetFrameLevel(self:GetFrameLevel() + 30)
            local background = menu:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            background:SetColorTexture(0.035, 0.025, 0.015, 1)
            AddControlBorder(menu)
            menu.entries = {}
            for index, option in ipairs(ForeverBagMoverFilters.options) do
                local entry = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
                menu.entries[index] = entry
                entry:SetSize(140, 22)
                entry:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - (index - 1) * 24)
                entry:SetText(option.label)
                entry:SetScript("OnClick", function()
                    if InCombatLockdown() then return end
                    local searchBox = frame.SearchBox or BagItemSearchBox
                    if not searchBox or not searchBox.SetText then
                        Message("This client does not expose a bag search box.")
                        menu:Hide()
                        return
                    end
                    if option.category and (not C_Container or
                        not (frame.EnumerateValidItems or frame.Items)) then
                        Message("This client does not expose category filtering for bags.")
                        menu:Hide()
                        return
                    end
                    ForeverBagMoverFilters.selected = index
                    searchBox:SetText(option.query)
                    searchBox:ClearFocus()
                    menu:Hide()
                    Refresh()
                end)
            end
            menu:Hide()
        end
        if self.menu:IsShown() then self.menu:Hide() else self.menu:Show() end
    end)
    filter:Hide()
    handle:SetSize(120, 20)
    handle:SetFrameStrata("DIALOG")
    handle:SetMovable(true)
    handle:SetClampedToScreen(true)
    handle:RegisterForDrag("LeftButton")
    local highlight = handle:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.04, 0.22, 0.36, 0.92)
    AddControlBorder(handle)
    local label = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    handle.label = label
    label:SetPoint("CENTER")
    label:SetText("Drag")
    local basePath, baseSize, baseFlags = label:GetFont()
    handle.baseFont = {path = basePath, size = baseSize, flags = baseFlags}

    -- In arrange mode the handle is a visible bar; with free move alone it is
    -- invisible over the title until hovered, so bags look unmodified.
    local function UpdateHandleAlpha()
        if draftPositions then
            handle:SetAlpha(1)
        elseif handle.hovered or handle.dragging then
            handle:SetAlpha(0.6)
        else
            handle:SetAlpha(0)
        end
    end
    handle.UpdateAlpha = UpdateHandleAlpha
    handle:SetScript("OnEnter", function()
        handle.hovered = true
        UpdateHandleAlpha()
    end)
    handle:SetScript("OnLeave", function()
        handle.hovered = false
        UpdateHandleAlpha()
    end)

    local function SavePosition()
        local key = handle.dragKey
        if not key or key ~= GetBagKey(frame) then return end
        if not CanDrag() or InCombatLockdown() then return end
        local x = handle:GetRight() + (handle.rightInset or 30)
        local y = handle:GetTop() + 4
        local bags = VisibleBags()
        local width, height = UIParent:GetWidth(), UIParent:GetHeight() - 28
        local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        if handle.groupStart then
            local origin = handle.groupOrigin
            local result = ForeverBagMoverLayout.Translate(handle.groupStart,
                x - origin.x, y - origin.y, width, height)
            if result then
                for bagKey, position in pairs(result) do Positions()[bagKey] = position end
            end
            ShowGuides()
        else
            local gx, gy
            if snapping and not IsAltKeyDown() then
                x, y, gx, gy = ForeverBagMoverLayout.Snap(
                    {key = key, x = x, y = y, w = frame:GetWidth() * scale,
                        h = frame:GetHeight() * scale}, bags, width, height, spacing)
            end
            Positions()[key] = {x = x, y = y}
            ShowGuides(gx, gy)
        end
        for other in pairs(handles) do ApplyPosition(other) end
        Refresh()
    end

    local function StopDragging()
        if handle.dragging then
            handle:StopMovingOrSizing()
            SavePosition()
            handle.dragging = false
            handle.dragKey = nil
            handle.groupStart = nil
            ShowGuides()
            -- Free-move drops write saved positions directly; keep the alt copy current.
            if not draftPositions then RememberCharacter() end
            Refresh()
        end
    end
    handle.StopDragging = StopDragging
    local grip = CreateFrame("Button", nil, UIParent)
    handle.resize = grip
    grip:SetSize(20, 20)
    grip:SetFrameStrata("DIALOG")
    grip:RegisterForDrag("LeftButton")
    -- Three diagonal strokes form a triangular bottom-right resize grip.
    -- Small textures keep the icon independent of client-specific atlases.
    for _, length in ipairs({5, 10, 15}) do
        for offset = 0, length - 1 do
            local pixel = grip:CreateTexture(nil, "OVERLAY")
            pixel:SetSize(2, 2)
            pixel:SetPoint("BOTTOMRIGHT", grip, "BOTTOMRIGHT",
                -2 - length + offset, 2 + offset)
            pixel:SetColorTexture(1, 0.78, 0.3, 0.95)
        end
    end
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(moveGroup and "Drag to resize the whole group together (50-150%)"
            or "Drag to resize this bag (50-150%)")
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local function StopResize()
        grip.origin = nil
        GameTooltip:Hide()
    end
    grip.StopResize = StopResize
    grip:SetScript("OnHide", StopResize)
    grip:SetScript("OnDragStop", StopResize)
    grip:SetScript("OnDragStart", function()
        local key = GetBagKey(frame)
        if not draftPositions or not key or InCombatLockdown() then return end
        StopDragging()
        for _, bag in ipairs(VisibleBags()) do
            draftPositions[bag.key] = {x = bag.x, y = bag.y}
        end
        if not draftScales then
            draftScales = {}
            for bagKey, value in pairs(ForeverBagMoverDB.scales) do draftScales[bagKey] = value end
        end
        local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        local left, top = frame:GetRight() * ratio - frame:GetWidth() * ratio, frame:GetTop() * ratio
        local width, height = frame:GetWidth() * ratio, frame:GetHeight() * ratio
        -- In group mode, scale every visible bag together around this bag's
        -- own top-left corner so their relative spacing is preserved and
        -- growing one bag can't make it overlap its neighbors.
        local group = {{key = key, left = left, top = top, width = width, height = height, scale = BagScale(key)}}
        if moveGroup then
            group = {}
            for _, bag in ipairs(VisibleBags()) do
                table.insert(group, {key = bag.key, left = bag.x - bag.w, top = bag.y,
                    width = bag.w, height = bag.h, scale = BagScale(bag.key)})
            end
        end
        grip.origin = {key = key, cursorX = x / UIParent:GetEffectiveScale(),
            cursorY = y / UIParent:GetEffectiveScale(), scale = BagScale(key),
            width = width, height = height, left = left, top = top, group = group}
        GameTooltip:Hide()
    end)
    grip:SetScript("OnUpdate", function()
        local origin = grip.origin
        if not origin then return end
        if not draftPositions or InCombatLockdown() or GetBagKey(frame) ~= origin.key then
            StopResize()
            return
        end
        local x, y = GetCursorPosition()
        local dx = x / UIParent:GetEffectiveScale() - origin.cursorX
        local dy = origin.cursorY - y / UIParent:GetEffectiveScale()
        local factor = 1 + (dx * origin.width + dy * origin.height)
            / (origin.width * origin.width + origin.height * origin.height)
        local value = math.max(50, math.min(150, math.floor(origin.scale * factor + 0.5)))
        local effectiveFactor = value / origin.scale
        for _, bag in ipairs(origin.group) do
            draftScales[bag.key] = math.max(50, math.min(150,
                math.floor(bag.scale * effectiveFactor + 0.5)))
            local newWidth = bag.width * effectiveFactor
            local newLeft = origin.left + (bag.left - origin.left) * effectiveFactor
            local newTop = origin.top + (bag.top - origin.top) * effectiveFactor
            draftPositions[bag.key] = {x = newLeft + newWidth, y = newTop}
        end
        Refresh()
    end)
    grip:Hide()

    handle:SetScript("OnDragStart", function(self)
        local key = GetBagKey(frame)
        if CanDrag() and key and not InCombatLockdown() then
            handle.resize.StopResize()
            -- Detach visible bags from Blizzard's stack before moving one bag.
            for other in pairs(handles) do
                local otherKey = GetBagKey(other)
                if otherKey and other:IsShown() and not HasPosition(Positions()[otherKey]) then
                    local right, top = other:GetRight(), other:GetTop()
                    if right and top then
                        local scale = other:GetEffectiveScale() / UIParent:GetEffectiveScale()
                        Positions()[otherKey] = {x = right * scale, y = top * scale}
                    end
                end
            end
            for other in pairs(handles) do ApplyPosition(other) end
            self.groupStart = moveGroup and VisibleBags() or nil
            self.groupOrigin = CopyPositions(Positions())[key]
            self.dragKey = key
            self.dragging = true
            UpdateHandleAlpha()
            self:StartMoving()
        end
    end)
    handle:SetScript("OnDragStop", StopDragging)
    handle:SetScript("OnHide", StopDragging)
    handle:SetScript("OnUpdate", function(self)
        if self.dragging then
            SavePosition()
        end
    end)
    handle:Hide()
    frame:HookScript("OnHide", function()
        handle:Hide()
        grip:Hide()
        toggle:Hide()
        filter:Hide()
    end)
    frame:HookScript("OnShow", function() Refresh() end)
    -- Resync the drag handle/grip whenever this frame moves, and re-assert our
    -- saved position if something else (e.g. Blizzard's own deferred default
    -- placement) moves it out from under us. ApplyPosition is cheap and a no-op
    -- when we have no saved position, so this is safe to call on every move -
    -- unlike a full Refresh(), which would recursively multiply every routine
    -- Refresh pass's own SetPoint calls.
    hooksecurefunc(frame, "SetPoint", function()
        ApplyPosition(frame)
        UpdateHandleGeometry(frame, handle)
    end)
end

-- Repositions one bag's drag handle and resize grip to match its current
-- frame geometry. Cheap to call often: the memoized fields make a no-op pass
-- (unchanged scale/position) skip all the Set* calls below.
UpdateHandleGeometry = function(frame, handle)
    if not ready then return end
    local key = GetBagKey(frame)
    local isFirstBag = key == "bag0" or key == "combined"
    -- A frame Blizzard just generated may not be anchored yet; GetRight/GetTop are nil until it is.
    local positioned = frame:GetRight() ~= nil and frame:GetTop() ~= nil
    local grip = handle.resize
    if draftPositions and not InCombatLockdown() and frame:IsShown() and key and positioned then
        local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        grip:ClearAllPoints()
        grip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT",
            frame:GetRight() * ratio, (frame:GetTop() - frame:GetHeight()) * ratio)
        grip:Show()
    else
        grip:Hide()
    end
    if handle.dragging and (handle.dragKey ~= key or not CanDrag()) then
        handle.StopDragging()
    end
    handle.UpdateAlpha()
    if CanDrag() and not InCombatLockdown() and frame:IsShown() and key and positioned then
        if not handle.dragging then
            local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
            local right, top, width = frame:GetRight(), frame:GetTop(), frame:GetWidth()
            if handle.lastScale ~= scale or handle.lastRight ~= right
                or handle.lastTop ~= top or handle.lastWidth ~= width then
                handle.lastScale, handle.lastRight, handle.lastTop, handle.lastWidth =
                    scale, right, top, width
                handle:ClearAllPoints()
                -- Keep dragging clear of the portrait, padlock/settings, and close button.
                local leftInset = 40 * scale
                handle.rightInset = (isFirstBag and 52 or 30) * scale
                local dragWidth = math.max(1, width * scale - leftInset - handle.rightInset)
                local dragHeight = 20 * scale
                handle:SetSize(dragWidth, dragHeight)
                local font = handle.baseFont
                if font and handle.lastFontScale ~= scale then
                    handle.lastFontScale = scale
                    handle.label:SetFont(font.path, font.size * scale, font.flags)
                end
                handle.label:SetText(dragWidth >= 90 * scale and "Drag to move" or (dragWidth >= 28 * scale and "Drag" or ""))
                handle:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT",
                    right * scale - handle.rightInset, top * scale - 4 * scale)
            end
        end
        handle:Show()
    else
        handle:Hide()
    end
end

local minimapButton

local function CreateMinimapButton()
    if minimapButton or not Minimap then return end
    minimapButton = CreateFrame("Button", "ForeverBagMoverMinimapButton", Minimap)
    -- Standard minimap-button geometry: the tracking border's ring sits in the
    -- top-left of its texture, so the backdrop and icon use matching offsets.
    minimapButton:SetSize(31, 31)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    local offset = ((Minimap:GetWidth() or 140) / 2 + 10) * math.cos(math.rad(45))
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", -offset, -offset)
    minimapButton:RegisterForClicks("LeftButtonUp")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local backdrop = minimapButton:CreateTexture(nil, "BACKGROUND")
    backdrop:SetSize(20, 20)
    backdrop:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -5)
    backdrop:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    minimapButton.icon = icon
    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    minimapButton:SetScript("OnClick", function()
        GameTooltip:Hide()
        BeginArrange()
    end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Forever Bag Mover")
        GameTooltip:AddLine("Click to open settings.", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapButton:SetScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
end

Refresh = function()
    if not ready then return end
    if panel then
        if draftPositions and not InCombatLockdown() then panel:Show() else panel:Hide() end
    end
    Attach(ContainerFrameCombinedBags)
    for index = 1, (NUM_CONTAINER_FRAMES or 13) do
        Attach(_G["ContainerFrame" .. index])
    end
    for frame, handle in pairs(handles) do
        ApplyPosition(frame)
        local key = GetBagKey(frame)
        if key then ForeverBagMoverFilters.Apply(frame, frame.GetBagID and frame:GetBagID() or frame:GetID()) end
        local isFirstBag = key == "bag0" or key == "combined"
        local showSettings = FreeMove()
        for _, texture in ipairs(handle.toggle.lockParts) do
            if showSettings then texture:Hide() else texture:Show() end
        end
        for _, texture in ipairs(handle.toggle.settingsParts) do
            if showSettings then texture:Show() else texture:Hide() end
        end
        handle.toggle.shackle:SetHeight(draftPositions and 3 or 7)
        if isFirstBag and frame:IsShown() and not InCombatLockdown()
            and not ForeverBagMoverDB.hideButtons then
            handle.toggle:SetFrameLevel(frame:GetFrameLevel() + 20)
            handle.toggle:Show()
            local searchBox = frame.SearchBox or BagItemSearchBox
            if searchBox and searchBox:IsShown() then
                local cleanup = frame.AutoSortButton or BagItemAutoSortButton
                handle.filter:SetSize(cleanup and cleanup:GetWidth() or 28,
                    cleanup and cleanup:GetHeight() or 26)
                handle.filter:ClearAllPoints()
                handle.filter:SetPoint("RIGHT", searchBox, "LEFT", -4, 0)
                handle.filter:SetFrameLevel(frame:GetFrameLevel() + 20)
                handle.filter:Show()
            else
                handle.filter:Hide()
            end
        else
            handle.toggle:Hide()
            handle.filter:Hide()
        end
        UpdateHandleGeometry(frame, handle)
    end
end

local hooked = false
local function InstallHook()
    if not hooked and type(UpdateContainerFrameAnchors) == "function" then
        hooksecurefunc("UpdateContainerFrameAnchors", Refresh)
        hooked = true
    end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(ForeverBagMoverSharedDB) ~= "table" then ForeverBagMoverSharedDB = {} end
        if type(ForeverBagMoverSharedDB.presets) ~= "table" then ForeverBagMoverSharedDB.presets = {} end
        if type(ForeverBagMoverSharedDB.characters) ~= "table" then ForeverBagMoverSharedDB.characters = {} end
        if type(ForeverBagMoverDB) ~= "table" then ForeverBagMoverDB = {} end
        if type(ForeverBagMoverDB.positions) ~= "table" then
            ForeverBagMoverDB.positions = {}
            if HasPosition(ForeverBagMoverDB) then
                for _, key in ipairs({"bag0", "combined"}) do
                    ForeverBagMoverDB.positions[key] = {
                        x = ForeverBagMoverDB.x, y = ForeverBagMoverDB.y,
                    }
                end
            end
        end
        local savedScale = ForeverBagMoverDB.scale
        if type(savedScale) ~= "number" or savedScale ~= savedScale
            or savedScale < 50 or savedScale > 150 then
            ForeverBagMoverDB.scale = 100
        end
        if type(ForeverBagMoverDB.scales) ~= "table" then ForeverBagMoverDB.scales = {} end
        for key, value in pairs(ForeverBagMoverDB.scales) do
            if type(value) ~= "number" or value ~= value or value < 50 or value > 150 then
                ForeverBagMoverDB.scales[key] = nil
            end
        end
        ForeverBagMoverDB.freeMove = ForeverBagMoverDB.freeMove == true
        ForeverBagMoverDB.hideButtons = ForeverBagMoverDB.hideButtons == true
        ForeverBagMoverDB.x = nil
        ForeverBagMoverDB.y = nil
        ready = true
    end
    if ready then
        if event == "PLAYER_LOGIN" then RememberCharacter() end
        InstallHook()
        Refresh()
        CreateMinimapButton()
    end
end)

local function StopAllDragging()
    for _, handle in pairs(handles) do
        handle.StopDragging()
        handle.resize.StopResize()
    end
end

local function Relayout()
    if UpdateContainerFrameAnchors then UpdateContainerFrameAnchors() end
    Refresh()
end

FinishArrange = function(save)
    if InCombatLockdown() then
        Message("Finish arranging after leaving combat.")
        return
    end
    if not draftPositions then return end
    StopAllDragging()
    if save then
        ForeverBagMoverDB.scales = draftScales or ForeverBagMoverDB.scales
        ForeverBagMoverDB.scale = draftScale or ForeverBagMoverDB.scale
        ForeverBagMoverDB.positions = draftPositions
        RememberCharacter()
    end
    draftPositions = nil
    draftScale = nil
    draftScales = nil
    Relayout()
    Message(save and "Layout saved." or "Changes canceled.")
end

local function ResetLayout()
    if InCombatLockdown() then
        Message("Reset after leaving combat.")
        return
    end
    if not draftPositions then
        draftPositions = CopyPositions(ForeverBagMoverDB.positions)
    end
    StopAllDragging()
    draftPositions = {}
    draftScales = {}
    draftScale = 100
    Relayout()
    -- The primary bag (bag0/combined) has no sibling to stack against, so
    -- Blizzard's own default placement for it can run a deferred second pass
    -- that moves it again after we've already relaid out. Pin wherever its
    -- first pass actually put it so that later move gets overridden back.
    for frame in pairs(handles) do
        local key = GetBagKey(frame)
        if (key == "bag0" or key == "combined") and frame:IsShown() then
            local right, top = frame:GetRight(), frame:GetTop()
            if right and top then
                local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
                draftPositions[key] = {x = right * scale, y = top * scale}
            end
        end
    end
    Relayout()
    Message("Default layout preview. Choose Done to save or Cancel to restore.")
end

local freeMoveButton
local buttonsVisibilityButton

local function SetButtonsHidden(hidden)
    if not ready then return end
    if InCombatLockdown() then
        Message("Change button visibility after leaving combat.")
        return
    end
    ForeverBagMoverDB.hideButtons = hidden
    if buttonsVisibilityButton then
        buttonsVisibilityButton:SetText(hidden and "Bag buttons: Hidden" or "Bag buttons: Shown")
    end
    Refresh()
    Message(hidden
        and "Bag buttons hidden. Use /fbm to arrange bags or /fbm buttons show to restore them."
        or "Bag buttons shown.")
end

local function SetFreeMove(enabled)
    if InCombatLockdown() then
        Message("Change free move after leaving combat.")
        return
    end
    StopAllDragging()
    ForeverBagMoverDB.freeMove = enabled and true or false
    if freeMoveButton then
        freeMoveButton:SetText(enabled and "Always movable: On" or "Always movable: Off")
    end
    Refresh()
    Message(enabled and "Bags are always movable. Drag a bag's title to move it; it saves when you let go."
        or "Bags are locked. Use the padlock on the backpack to arrange them.")
end

local function CreatePanel()
    if panel then return end
    panel = CreateFrame("Frame", "ForeverBagMoverArrangePanel", UIParent)
    panel:SetSize(340, 374)
    panel:SetPoint("TOP", UIParent, "TOP", 0, -60)
    panel:SetFrameStrata("DIALOG")
    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.05, 0.95)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Arrange bags")
    local function AddButton(name, text, x, action, y)
        local button = CreateFrame("Button", name, panel, "UIPanelButtonTemplate")
        button:SetSize(100, 24)
        button:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", x, y and (y + 32) or 12)
        button:SetText(text)
        button:SetScript("OnClick", action)
        return button
    end
    local nameBox = CreateFrame("EditBox", "ForeverBagMoverPresetName", panel, "InputBoxTemplate")
    nameBox:SetSize(198, 24)
    nameBox:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 310)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(40)
    nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    local caption = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    caption:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 337)
    caption:SetText("Preset name (saving replaces the same name)")
    local presetChoice, characterChoice
    local presetButton, characterButton
    local function SelectNext(entries, selected, excluded)
        local names = ForeverBagMoverPresets.Names(entries, excluded)
        if #names == 0 then return nil end
        for index, name in ipairs(names) do
            if name == selected then return names[index % #names + 1] end
        end
        return names[1]
    end
    local function Preview(snapshot)
        if not draftPositions or InCombatLockdown() then return end
        local restored = ForeverBagMoverPresets.Restore(snapshot, UIParent:GetWidth(), UIParent:GetHeight())
        if not restored then Message("That layout is missing or invalid.") return end
        StopAllDragging()
        draftPositions = restored
        Relayout()
        Message("Layout preview loaded. Choose Done to keep it or Cancel to restore.")
    end
    AddButton("ForeverBagMoverSavePreset", "Save preset", 228, function()
        if not draftPositions or InCombatLockdown() then return end
        local name = ForeverBagMoverPresets.Name(nameBox:GetText())
        if not name then Message("Enter a preset name (1-40 characters; no | or control characters).") return end
        StopAllDragging()
        local positions = CopyPositions(draftPositions)
        -- Include visible bags still using Blizzard's default positioning.
        for _, bag in ipairs(VisibleBags()) do positions[bag.key] = {x = bag.x, y = bag.y} end
        ForeverBagMoverSharedDB.presets[name] = ForeverBagMoverPresets.Capture(
            positions, UIParent:GetWidth(), UIParent:GetHeight())
        presetChoice = name
        presetButton:SetText("Preset: " .. name)
        nameBox:ClearFocus()
        Message("Saved account-wide preset: " .. name)
    end, 278)
    presetButton = AddButton("ForeverBagMoverPresetSelect", "Preset: click to choose", 12, function(self)
        presetChoice = SelectNext(ForeverBagMoverSharedDB.presets, presetChoice)
        self:SetText(presetChoice and ("Preset: " .. presetChoice) or "No saved presets")
        if presetChoice then nameBox:SetText(presetChoice) end
    end, 246)
    presetButton:SetWidth(208)
    AddButton("ForeverBagMoverLoadPreset", "Load preset", 228, function()
        if not presetChoice then Message("Click the preset selector to choose a preset.") return end
        Preview(ForeverBagMoverSharedDB.presets[presetChoice])
    end, 246)
    characterButton = AddButton("ForeverBagMoverCharacterSelect", "Character: click to choose", 12, function(self)
        characterChoice = SelectNext(ForeverBagMoverSharedDB.characters, characterChoice, CharacterKey())
        self:SetText(characterChoice or "No other characters yet")
    end, 214)
    characterButton:SetWidth(208)
    AddButton("ForeverBagMoverCopyCharacter", "Copy layout", 228, function()
        if not characterChoice then Message("Log into an alt with this version, then choose it here.") return end
        Preview(ForeverBagMoverSharedDB.characters[characterChoice])
    end, 214)
    local libraryHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    libraryHint:SetPoint("BOTTOM", panel, "BOTTOM", 0, 217)
    libraryHint:SetText("Click selectors to cycle. Presets are shared across characters.")
    local function Arrange(mode)
        if not draftPositions or InCombatLockdown() then return end
        StopAllDragging()
        local result = ForeverBagMoverLayout.Arrange(VisibleBags(), mode, spacing,
            UIParent:GetWidth(), UIParent:GetHeight() - 28)
        if not result then
            Message("That layout will not fit on screen. Try Grid or a smaller gap.")
            return
        end
        for key, position in pairs(result) do draftPositions[key] = position end
        Refresh()
    end
    AddButton("ForeverBagMoverRow", "Row", 12, function() Arrange("row") end, 140)
    AddButton("ForeverBagMoverColumn", "Column", 120, function() Arrange("column") end, 140)
    AddButton("ForeverBagMoverGrid", "Grid", 228, function() Arrange("grid") end, 140)
    AddButton("ForeverBagMoverSnap", "Snap: On", 12, function(self)
        if InCombatLockdown() then return end
        snapping = not snapping
        self:SetText(snapping and "Snap: On" or "Snap: Off")
        ShowGuides()
    end, 108)
    AddButton("ForeverBagMoverGroup", "Group: Off", 120, function(self)
        if InCombatLockdown() then return end
        StopAllDragging()
        moveGroup = not moveGroup
        self:SetText(moveGroup and "Group: On" or "Group: Off")
    end, 108)
    AddButton("ForeverBagMoverGap", "Gap: 8", 228, function(self)
        if InCombatLockdown() then return end
        spacing = (spacing + 4) % 28
        self:SetText("Gap: " .. spacing)
    end, 108)
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", panel, "BOTTOM", 0, 110)
    hint:SetText("Drag a bag corner to resize. Hold Alt to bypass snapping.")
    freeMoveButton = AddButton("ForeverBagMoverFreeMove",
        FreeMove() and "Always movable: On" or "Always movable: Off", 12, function()
            SetFreeMove(not FreeMove())
        end, 46)
    freeMoveButton:SetWidth(316)
    buttonsVisibilityButton = AddButton("ForeverBagMoverButtonsVisibility",
        ForeverBagMoverDB.hideButtons and "Bag buttons: Hidden" or "Bag buttons: Shown", 12, function()
            SetButtonsHidden(not ForeverBagMoverDB.hideButtons)
        end, 14)
    buttonsVisibilityButton:SetWidth(316)
    AddButton("ForeverBagMoverDone", "Done", 12, function() FinishArrange(true) end)
    AddButton("ForeverBagMoverCancel", "Cancel", 120, function() FinishArrange(false) end)
    AddButton("ForeverBagMoverReset", "Reset layout", 228, ResetLayout)
end

BeginArrange = function()
    if InCombatLockdown() then
        Message("Arrange bags after leaving combat.")
        return
    end
    if not draftPositions then
        draftPositions = CopyPositions(ForeverBagMoverDB.positions)
    end
    RememberCharacter()
    CreatePanel()
    if OpenAllBags then OpenAllBags() elseif OpenBackpack then OpenBackpack() end
    Refresh()
    Message(FreeMove() and "Arrange mode. Drag titles or corners, then choose Done to save."
        or "All bags unlocked. Drag their highlighted titles, then choose Done to save.")
end

SLASH_FOREVERBAGMOVER1 = "/fbm"
SlashCmdList.FOREVERBAGMOVER = function(input)
    local command = input:lower():match("^%s*(.-)%s*$")
    if command == "" or command == "arrange" or command == "unlock" then
        BeginArrange()
    elseif command == "done" or command == "lock" then
        FinishArrange(true)
    elseif command == "cancel" then
        FinishArrange(false)
    elseif command == "reset" then
        BeginArrange()
        ResetLayout()
    elseif command == "buttons hide" or command == "buttons show" then
        SetButtonsHidden(command == "buttons hide")
    elseif command == "free" or command == "free on" or command == "free off" then
        if command == "free" then
            SetFreeMove(not FreeMove())
        else
            SetFreeMove(command == "free on")
        end
    else
        Message("Commands: /fbm, /fbm done, /fbm cancel, /fbm reset, /fbm free [on|off], /fbm buttons [hide|show]")
    end
end
