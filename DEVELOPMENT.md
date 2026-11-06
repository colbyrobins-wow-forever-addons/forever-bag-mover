# Development validation

Bag scaling development change; release version unchanged.

Run `python tests/check_addon.py` with lupa available. Regression coverage includes
scale preview, saving, canceling, bounds, and combat blocking.
Local execution is blocked: existing `.test-deps/lupa` raises PermissionError;
a fresh dependency install failed because package-host DNS was unavailable.

Pending target-client validation: separate and combined bags at 50%, 100%, and
150%; drag/snap/group layouts; close/reopen; Done then reload; Cancel; entering
and leaving combat; resolution/UI-scale changes. Check item tooltips and clicks.
User acceptance has not been performed. Do not assign a release version yet.

The repository has no commits and its existing project files are all untracked.
Changes remain uncommitted to avoid absorbing the existing work into this feature.

## Test deployment — 2026-11-05
Deployed the uncommitted workspace build to C:\Program Files (x86)\World of Warcraft\_forever_\AddOns\ForeverBagMover. All five deployed files passed SHA-256 comparison. Previous installation backed up under dist/deployment-backups/ForeverBagMover-20261105-192242/ForeverBagMover. Release version unchanged; in-game user acceptance pending.

Deployment correction: confirmed running Wow.exe is in _forever_. The earlier root AddOns deployment was not discovered by the game. Installed and hash-verified all five files in C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\ForeverBagMover. User must restart the client to discover this newly installed addon; acceptance remains pending.

Individual scaling added and deployed 2026-11-05 to _forever_\Interface\AddOns\ForeverBagMover; backup: dist/deployment-backups/IndividualScale-20261105-192803. All deployed file hashes matched. Full mocked Lua regression suite passed using lupa from .scale-test-deps (preloaded before running tests/check_addon.py via runpy). Covers individual isolation, saving, canceling, global bounds and combat blocking. In-game acceptance pending; release version unchanged. Existing untracked repository state preserved.

Corner resize replaces the scale selector/buttons (2026-11-05). Mocked regression suite passed with isolated lupa: individual resizing, isolation, Cancel, Done, upper bound, and combat interruption. Deployed with SHA-256 verification to _forever_\Interface\AddOns\ForeverBagMover; backup dist/deployment-backups/CornerResize-20261105-193241. Test corner alignment, combined bags, screen edges, and mouse behavior in-game. Acceptance pending; version unchanged; workspace remains uncommitted.

Resize grip visual update: replaced square background and text with three gold diagonal strokes forming a corner triangle. Mocked regression suite passed; deployed Lua file hash verified. Backup: dist/deployment-backups/TriangleGrip-20261105-193426. In-game visual acceptance pending.
