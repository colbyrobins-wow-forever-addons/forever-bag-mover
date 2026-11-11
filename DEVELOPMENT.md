# Development and release workflow

Develop, check locally, test in game, obtain acceptance, then commit. Release
versioning and publication are separate requested steps, as in PallySealCooldowns.

## Development cycle

1. Make a focused change and add relevant regression coverage.
2. From the repository root, run `python tests/check_addon.py` with Lupa
   available, then `git diff --check`. The harness uses `lupa.lua51` and prepends
   `.test-deps` to its import path. Local dependencies are never distributed.
3. Keep feature changes uncommitted while iterating through in-game testing.
   Record `git rev-parse --short HEAD` and `git status --short` with each test.
4. Deploy for testing when requested, backing up the existing addon first and
   verifying copied files against the source. The previously verified target is
   `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\ForeverBagMover`.
   Confirm the active client path before future deployment. A source junction is
   optional and requires a separate request; this setup does not establish one.
5. Test in Forever 1.60.1 (record the actual build). Reload after Lua edits;
   restart after adding files or changing the TOC. Check the README's in-game
   scenarios plus scenarios specific to the change. Fix problems and repeat.
6. After user acceptance, commit the source, tests, documentation, and required
   assets together. Keep the release version unchanged until release preparation.

The repository currently has no Docker check wrapper or CI release pipeline.
Use its existing Python/Lua harness; PallySealCooldowns commands do not apply here.
Mocked checks cannot establish visual layout, combat safety, or client compatibility.

## Release gate

After the user accepts in-game results and requests release preparation:

1. Choose the version and update `ForeverBagMover/ForeverBagMover.toc`,
   `CHANGELOG.md`, `README.md`, and `CurseForgeDescription.md` consistently.
2. Run local checks and compare runtime files with the accepted test build.
   Changes beyond release metadata require relevant retesting.
3. Commit release preparation. Create archives under ignored `dist/`, containing
   only the addon folder and required runtime files. Tags and publication are
   separate explicit actions; there is no configured publishing automation.
4. Push or publish only when requested, and record publication separately from
   preparation. Local Git history is not a remote backup (no remote is configured).

## Current work — 2026-11-10

- Unreleased work: workflow setup only; runtime and TOC version 0.7.0 unchanged.
- Local verification: documentation references and TOC-listed files checked;
  see the setup commit for the exact changes. No new in-game testing performed.
- Pending client checks: Always movable hover/drag/snap/group behavior, title-bar
  clicks, sliders icon and panel layout, persistence after reload, and combat hiding.
  Earlier scaling and combined-bag scenarios without explicit acceptance remain
  pending; see the historical records below.
- Known unresolved issues: prior `.test-deps/lupa` PermissionError; the historical
  workaround used `.scale-test-deps`. Do not treat historical results as a fresh run.
- Acceptance: the consumable taint fix was accepted on 2026-11-07; remaining
  scenarios were not individually confirmed. The version string alone does not
  establish what was published.

## Reusable test record

- Date and change:
- Base Git commit and uncommitted files:
- Local commands and observed results:
- Client build, installation path, and deployment/backup identification:
- In-game scenarios and observed results:
- Pending cases and known issues:
- User acceptance (who requested/confirmed what, and when):
- Release preparation and publication status:

## Historical validation records

The entries below retain their original chronology and claims. Statements about
an untracked repository describe that earlier state, not the current checkout.

# Development validation

## 2026-11-07: Release preparation 0.7.0

- User requested a release after confirming the consumable taint fix in-game.
  Recorded as release authorization; the remaining Always movable in-game
  checks were not separately reported.
- Minor version for the new Always movable feature, plus the taint fix.
  Updated TOC, CHANGELOG, README, CurseForgeDescription.
- Runtime files match deployed test build 288e3a9 apart from the TOC version.

## 2026-11-07: Fix blocked consumable use (taint)

- Symptom: right-clicking a consumable in the bags gave an addon-blocked
  action message. Cause: `Filters.lua` called Blizzard's
  `button:SetMatchesSearch()` on every slot each Refresh (even with
  "All items") and hooked it, so the addon wrote item-button search/context
  fields and the secure use path then ran tainted.
- Fix: category dimming now uses an addon-owned overlay texture per button
  (weak table); Blizzard item-button methods are never called or hooked.
  "All items" touches nothing. Native search dimming is left to Blizzard.
- Local: `tests/check_addon.py` passes (lupa from `.scale-test-deps`); filter
  test now errors if `SetMatchesSearch` is called.
- In-game pending: right-click food/potion/bandage with each filter selected,
  in and out of combat; category dimming looks right; search box still dims.
- Deployed commit 288e3a9 (no uncommitted changes; includes the free-move
  feature) to `_forever_\Interface\AddOns\ForeverBagMover`; all five files
  SHA-256 verified. Backup: dist/deployment-backups/TaintFix-20261107-205603.
  Version unchanged (0.6.0); in-game acceptance pending.
- 2026-11-07 in-game: user confirmed consumables no longer give the blocked
  action message. Other free-move in-game checks remain pending.

## 2026-11-07: Always movable (free move) setting

- New per-character `ForeverBagMoverDB.freeMove` (default off; non-boolean
  saved values reset to off). Toggle via the Arrange panel's
  **Always movable** button (new bottom row; panel grew 310 -> 342 px) or
  `/fbm free [on|off]`. Cannot change in combat.
- When on and not arranging: title drag handles stay shown but transparent
  (alpha 0, 0.6 on hover/drag); drops write straight to saved positions and
  refresh the character snapshot. Snap, Alt-bypass, and Group still apply.
  Resize grips stay arrange-only. The padlock is replaced by a code-drawn
  sliders icon that opens/saves the Arrange panel. Arrange mode still drafts;
  Cancel does not change the setting.
- Test harness fixes: the suite was failing before this change (mock frames
  lacked `GetFont`/`SetFont`, and three assertions predated 0.6.0's
  reset-pins-primary-bag behavior). Added those stubs, updated those
  assertions, and gave mock textures a `scripts` table.
- Local: `tests/check_addon.py` passes (run with lupa from `.scale-test-deps`;
  `.test-deps/lupa` still raises PermissionError), including new free-move
  regression coverage. TOC file check and `git diff --check` pass.
- In-game pending: invisible handle does not block anything on the title bar;
  hover feedback; drag/snap/group in free mode; sliders icon look; panel layout
  with the new row; reload keeps the setting and positions; combat hiding.
- Not deployed. No version change (TOC stays 0.6.0).

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
