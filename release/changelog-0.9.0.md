# 0.9.0

- **Reagent bag stays attached to the combined backpack.** Any bag touching the
  combined backpack, such as the reagent bag, is now glued to it. It moves with
  the backpack, follows it when the backpack is resized or changes size, and
  stays attached after reloads and relogs. Presets and character copies keep
  it attached. Drag a bag away from the backpack to unglue it.
- **Movable key ring.** The key ring can now be moved and saved like any other
  bag, and can be glued to the combined backpack too.
- New **Key ring with bags** setting in the settings panel, also available as
  `/fbm keyring on` and `/fbm keyring off`. It opens the key ring with your
  backpack or combined bag and closes it with them. Off by default; saves per
  character. During combat it waits until combat ends.

Targets Forever beta 1.60.1, interface 16001. The mocked regression suite passes locally.
