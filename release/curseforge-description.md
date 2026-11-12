# Forever Bag Mover

Move each Blizzard inventory bag independently, or arrange the combined-bag
window as one piece. Positions and sizes save per character, with a separate
layout for combined bags. Existing saved positions migrate automatically.

## Features

- **Free placement.** Drag any bag anywhere on screen - separately or as a group.
- **Always movable (optional).** Turn it on to drag bags by their title at any
  time without entering Arrange mode; each move saves when you let go.
- **Minimap button.** Click the bag icon on the minimap to open the settings
  panel. Drag it around the minimap edge, or hide it if you prefer `/fbm`.
- **Hideable bag buttons (optional).** Hide the padlock and filter buttons on
  your bags from the settings panel or with `/fbm buttons hide`.
- **Per-bag resizing.** Drag a bag's corner to scale it smoothly from 50% to
  150%. Each bag slot and the combined bag keep their own size.
- **Group mode.** Move or resize every open bag together while preserving
  their relative spacing. Resizing with Group on scales the whole group
  together, so bags can't grow into overlapping their neighbors.
- **Snap and guides.** Bags snap to screen edges and to each other, with
  on-screen alignment guides. Hold **Alt** to bypass snapping temporarily.
- **Row / Column / Grid layouts.** One click to arrange all currently open
  bags, with adjustable spacing.
- **Reset layout.** Instantly preview Blizzard's default position and default
  (100%) size for every bag. Keep it with Done or back out with Cancel.
- **Presets.** Save named layouts to an account-wide library and load them on
  any character. Copy another character's last saved layout directly.
- **Item filtering.** A funnel icon next to the search box filters to Food,
  Drinks, Potions, Quest items, Reagents, Equipment, or Junk.
- Everything is a safe preview until you confirm it - Cancel always restores
  your last saved layout, and reloading without saving discards the preview.

## Install and use

1. Copy the `ForeverBagMover` folder into your client's `Interface/AddOns`.
2. Restart WoW and enable **Forever Bag Mover**.
3. Open your backpack and click the **closed padlock** beside its close button
   to enter **Arrange bags** mode (the combined bag has the same button).
   `/fbm` also works.
4. Drag the highlighted **Drag to move** bar on each bag. Drag a bag's bottom
   corner to resize it.
5. Click the **open padlock** or **Done** to save and hide the drag
   highlights, or **Cancel** to discard changes and restore your saved layout.

Commands: `/fbm` (arrange), `/fbm done`, `/fbm cancel`, `/fbm reset`,
`/fbm free` (toggle always movable; also `/fbm free on` / `/fbm free off`),
`/fbm buttons hide` / `/fbm buttons show`, `/fbm minimap hide` / `/fbm minimap show`.

## Known compatibility notes

FrameUnlocker can fight with Forever Bag Mover over bag frame positioning,
since both addons try to control the same frames' movement. If you use
FrameUnlocker, exclude your bags from it (or disable it) to avoid position
fights with this addon.

## Changelog

See the full version history in `CHANGELOG.md`.
