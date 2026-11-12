# 0.8.0

- New **minimap button**: click the bag icon at the lower-left edge of the
  minimap to open the Forever Bag Mover settings panel. It stays available when
  bag buttons are hidden; the panel still cannot open during combat. Drag the
  icon to move it anywhere around the minimap edge; its position saves per
  character.
- New **Minimap icon: Shown/Hidden** toggle in the settings panel, also
  available as `/fbm minimap hide` and `/fbm minimap show`. It saves per
  character, and `/fbm` still opens the panel while the icon is hidden.
- New **Bag buttons: Shown/Hidden** toggle in the settings panel, also available
  as `/fbm buttons hide` and `/fbm buttons show`. It hides the padlock/settings
  and filter buttons on your bags, saves per character, and persists after
  reload.

Targets Forever beta 1.60.1, interface 16001. The mocked regression suite passes locally.
