# Unreleased

- New **Always movable** setting (Arrange panel or `/fbm free on|off`): drag any
  bag by its title at any time without entering Arrange mode. The drag area is
  invisible until hovered, and each drop saves immediately. While it is on, the
  padlock becomes a sliders button that opens the Arrange panel. Off by default.
- Fix "Interface action failed because of an AddOn" when right-clicking a
  consumable in the bags. Category filters now dim items with their own overlay
  instead of calling Blizzard's item-button search code, which tainted item use.

# 0.6.0

- Scale the "Drag to move" handle and its label with each bag's individual size.
- Reset layout now also resets each bag back to its default size, not just its position.
- Reduce lag while dragging or resizing bags by skipping redundant handle/grip
  updates when nothing about that bag changed.
- Fix a crash when a bag frame is shown for the first time, before Blizzard has
  anchored it.
- Keep the drag handle and resize grip in sync with a bag's real position,
  including when something else moves the frame after the fact.
- With Group: On, resizing any bag now scales the whole group together so
  relative spacing is preserved and bags can no longer grow into overlapping
  their neighbors.

Known conflicts: FrameUnlocker can fight with Forever Bag Mover over bag frame
positioning, since both addons try to control the same frames' movement. If
you use FrameUnlocker, exclude your bags from it (or disable it) to avoid
position fights with this addon.

# 0.5.0

- Save named presets in an account-wide library and load them on alts.
- Copy another character's last saved layout through the Arrange panel.
- Preview loaded layouts before committing with Done; Cancel restores the prior layout.
- Adapt copied positions to the destination screen size.
- Preserve independent separate-bag and combined-bag positions in snapshots.
- Saving a preset with the same name replaces it. Source characters must load
  this version and log out or reload before their layouts are available to alts.

Validated with Lua 5.1 and mocked game APIs. In-game UI and cross-character
SavedVariables persistence still need live-client verification.

# 0.4.0

- Snap bags to screen edges and neighboring bags, with visible alignment guides.
- Hold Alt to temporarily bypass snapping or turn snapping off in Arrange mode.
- Preview Row, Column, and Grid layouts with adjustable spacing.
- Move all open bags as a group while preserving their spacing and screen bounds.
- Keep all layout changes reversible through Cancel until saved with Done.
- Reject layouts that cannot fit rather than leaving bags off-screen.

Validated with geometry and mocked WoW regression checks. In-game visual and
interaction testing is still needed for these new tools.

# 0.3.6

- Restore saved positions when ordinary bag windows open or relayout in combat.
- Continue blocking dragging and layout editing during combat.
- Defer protected-frame positioning until combat ends.

# 0.3.5

- Increase padlock contrast with a dark backing, gold outline, and larger bright icon.
- Give drag areas a solid blue backing, gold outline, and white text.
- Use "Drag to move" labels where space permits.

# 0.3.4

- Replace the header text button with a compact gold padlock beside the close button.
- Show an open shackle when movement is enabled and action tooltips on hover.
- Soften drag highlights and keep them clear of the padlock.

# 0.3.3

- Restore the Move/Lock button directly when the backpack opens.
- Draw the toggle above bag header artwork.
- Add a regression check for closing and reopening without an inventory update.

# 0.3.2

- Label the single backpack toggle Move/Lock to make its global behavior clear.
- Clicking Move enables dragging all bags; Lock saves and locks all bags.

# 0.3.1

- Add an Arrange/Done toggle inside the backpack and combined-bag header.
- Anchor it at TOPLEFT (55, -2) to avoid overlapping the bag above.
- Keep title-bar drag highlights clear of the toggle.

# 0.3.0

- Replace permanent per-bag buttons with a single Arrange bags mode.
- Use highlighted title areas to drag bags, with Done, Cancel, and Reset layout.
- Preview edits without saving until Done; Cancel restores the saved layout.
- Hide controls outside Arrange mode and temporarily during combat.
- Keep existing positions and legacy slash-command aliases.

Validated with mocked WoW APIs; in-game visual checks are still required.

# 0.2.0

- Move and lock each separate inventory bag independently.
- Save positions by bag slot, including when bags open in a different order.
- Preserve a separate combined-bag position and migrate existing saved positions.
- Keep other visible bags in place when dragging one bag.
- `/fbm lock`, `/fbm unlock`, and `/fbm reset` apply to all bags.

Validated with mocked WoW APIs; live-client verification is still required.
