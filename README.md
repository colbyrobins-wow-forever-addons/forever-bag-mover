# Forever Bag Mover

Move each Blizzard inventory bag independently or arrange the combined-bag
window. Positions save per character and bag slot, with a separate combined-bag
layout. Existing saved positions migrate automatically.

## Install and use

1. Copy the `ForeverBagMover` folder into your client's `Interface/AddOns`.
2. Restart WoW and enable **Forever Bag Mover**.
3. Open your backpack and click the **closed padlock** beside its close button to enter
   **Arrange bags** mode. The combined bag has the same button. `/fbm` also works.
4. Drag the highlighted title area on each bag.
5. Click the **open padlock** in the backpack header or **Done** in the control panel to save and hide the drag
   highlights, or **Cancel** in the control panel to
   discard changes and restore your saved layout.
6. **Reset layout** previews Blizzard's default positions for all bags. Choose
   **Done** to keep the reset or **Cancel** to restore your previous layout.

The single padlock button controls movement for all bags. Other bags never
show a toggle button.

**Always movable:** turn this on in the Arrange panel (or with `/fbm free on`)
to drag any bag by its title at any time, without entering Arrange mode. The
drag area stays invisible until you hover it, and each move saves as soon as you
let go, so there is no Cancel for these moves. While it is on, the padlock becomes a
**sliders icon** that opens the Arrange panel for presets, layouts, resizing,
and reset; those still preview until Done. Dragging is blocked in combat.

Changes are previews until you click the open padlock or Done; reloading without Done discards the preview.
The panel and highlights hide during combat and return when combat ends.
Click the **funnel icon** to the left of the backpack/combined-bag search box to choose
Food, Drinks, Potions, Quest items, Reagents, Equipment, or Junk.
**All items** clears the filter and search. Food, Drinks, and Potions use the
client's built-in search terms; matching depends on the client's search behavior.
Other filters use item metadata: quest flags/class, reagent/trade-goods classes,
equipment slots, and poor quality. Reagents includes crafting trade goods.
The selected category also applies when editing the search box manually.
Filters apply across open inventory bags and dim nonmatching items.
The button and dropdown hide during combat along with the padlock.

Normal bag use shows the backpack/combined-bag **filter and padlock** buttons. They sit
inside the header so it does not overlap the bag stacked above. The drag area
leaves space for the padlock and the bag's close button. The filter icon sits
on the search row, opposite Clean Up Bags, and matches its button dimensions.

Commands: `/fbm` (arrange), `/fbm done`, `/fbm cancel`, `/fbm reset`,
`/fbm free` (toggle always movable; also `/fbm free on` / `/fbm free off`).
Legacy `/fbm unlock` enters Arrange mode and `/fbm lock` saves and exits.

Use `/fbm buttons hide` to hide both the settings/padlock and filter buttons,
or `/fbm buttons show` to restore them. This preference saves per character
and persists after reload. `/fbm` still opens Arrange mode while buttons are
hidden; use Done/Cancel in the panel or the slash commands to finish.
Change button visibility outside combat. Hiding buttons leaves the current
filter and search unchanged; select All items before hiding if needed.
The `/fbm` panel also has a **Bag buttons: Shown/Hidden** toggle for the same
setting. It saves immediately, including when you close the panel with Cancel.

Click the bag icon at the lower-left edge of the minimap to open the same
settings panel. This shortcut stays available when the bag header buttons are
hidden. Like `/fbm`, opening the panel is blocked during combat.

## Arrange tools (0.4.0)

- **Row / Column / Grid:** Preview a layout for currently open bags, ordered by
  bag slot. Layouts that cannot fit on screen leave the current layout unchanged.
- **Resize grip:** In Arrange mode, drag the bottom-right corner of a bag to
  resize it smoothly from 50% to 150%. Each bag slot and the combined bag retain
  their own scale. Done saves; Cancel restores. Presets and Reset layout affect
  positions only.
- **Gap:** Cycle spacing through 0–24 UI pixels in steps of 4 (default 8).
  Click a layout button again to apply the new spacing.
- **Snap:** Drag near another bag's edges or the screen edge to align. Cyan
  guides show the alignment. Hold **Alt** to bypass snapping temporarily.
- **Group:** Drag any bag to move all currently open bags together. Relative
  spacing stays unchanged, and movement stops at screen boundaries. Group
  dragging does not snap. Closed bags are not moved.

These tools change the preview only; Done saves and Cancel restores the prior
layout. Snap, Group, and Gap preferences last for the current UI session.

## Presets and copying layouts (0.5.0)

- Enter Arrange mode, type a name in **Preset name**, and click **Save preset**.
  This saves the current preview to the account-wide library immediately.
  Saving the same name replaces that preset; Cancel does not undo a preset save.
- Click the **Preset** selector to cycle through names, then **Load preset**.
  Loading changes only the preview. Choose Done to apply it or Cancel to undo.
- Click the **Character** selector to cycle through other characters, then
  **Copy layout** to preview that character's last saved layout.
- Source characters must log into version 0.5.0 or later first. Log out or reload
  to write their layouts to disk before switching characters. Sharing is within
  the same WoW account/client installation, not between separate accounts.
- Presets include separate and combined bag positions already configured.
  They do not change your combined-bags setting, equipped bags, or UI scale.
- Coordinates adapt proportionally to the destination screen size. Different
  bag sizes may still need adjustment; preview the result before saving.
- Preset names are case-sensitive and limited to 40 characters. Presets and
  character copies remain independent after loading.

## Minimap button and bag-button toggle (0.8.0)

- Click the bag icon on the minimap to open the settings panel.
- Hide or show the bag header buttons from the panel or with
  `/fbm buttons hide|show`.

## Always movable and item-use fix (0.7.0)

- New **Always movable** setting (Arrange panel or `/fbm free on|off`): drag
  any bag by its title at any time; each drop saves immediately. Off by default.
- Fixed "Interface action failed because of an AddOn" when right-clicking a
  consumable in the bags.

## Handle scaling, group resize, and fixes (0.6.0)

- The **Drag to move** handle and its label now scale with each bag's own size.
- **Reset layout** also resets each bag back to its default (100%) size, not
  just its position.
- With **Group** on, resizing any bag now scales the whole group together,
  preserving relative spacing so bags can't grow into overlapping their
  neighbors.
- Fixed lag while dragging or resizing bags, and a crash that could occur when
  a bag frame was shown for the first time before Blizzard had anchored it.
- The drag handle and resize grip now stay in sync with a bag's real position
  if something else moves the frame afterward.

### Known conflicts
FrameUnlocker can fight with Forever Bag Mover over bag frame positioning,
since both addons try to control the same frames' movement. If you use
FrameUnlocker, exclude your bags from it (or disable it) to avoid position
fights with this addon.

## Compatibility status

This addon targets modern Blizzard container APIs on Forever 1.60.1.
New Arrange tools require in-game visual testing before release.
The TOC interface value `16001` matches its existing installed addons.
For future builds, run `/dump GetBuildInfo()` in game:
the fourth return value is the interface number. If needed, replace the TOC's
`## Interface:` value with that number and restart the client. Changing this
number only controls version recognition; it does not prove API compatibility.

Implementation reference: Blizzard UI source mirror, Mainline ContainerFrame.lua:
https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua

## In-game validation

- Enter Arrange mode, move bags, and choose Done. Reopen and reload: positions persist.
- Move bags and choose Cancel: the prior layout returns.
- Reset layout, then Cancel: saved positions return. Reset and Done: defaults persist.
- Check separate bags and combined bags, including reopening bags in a different order.
- Confirm other open bags stay in place when one moves.
- Enter combat while arranging: controls hide and return afterward.
- Change UI scale or resolution; verify drag highlights align with the title bars.
- Confirm bag names, close buttons, item actions, and sorting remain usable.

Mocked regression checks: `python tests/check_addon.py` (requires lupa, optionally
installed into `.test-deps`). Visual layout and combat taint need live-client testing.

## Development workflow

See [DEVELOPMENT.md](DEVELOPMENT.md) for local checks, in-game acceptance,
commit timing, and release preparation.
