# Repository workflow

- Follow DEVELOPMENT.md for local checks, in-game testing, and release gates.
- Develop without changing the established TOC version.
- Like PallySealCooldowns, keep feature and fix changes uncommitted through
  in-game testing; commit after the user accepts the results. This project rule
  overrides the general preference for committing immediately after local checks.
- Identify test builds by base Git commit and disclose uncommitted changes.
- Add focused regression coverage for behavior changes. Record local checks
  separately from actual client results and user acceptance.
- Deploy or create/change a client directory junction only when requested;
  back up any real installation folder first. Never recursively delete a junction.
- Assign versions and prepare release archives or tags only after acceptance
  and a request to prepare a release. Push or publish only when requested.
- Pushing a `v*` tag publishes: `.github/workflows/ci-release.yml` creates the
  GitHub Release and uploads to CurseForge. Push only the requested tag, and
  only when the user asks to publish that version. Workflow maintenance may be
  committed after local checks.
- Track source, tests, documentation, and required assets. Exclude dependencies,
  deployment backups, and build archives. Preserve unrelated local edits.
- Keep personal paths, credentials, and account/character details out of new
  documentation and commits; use <workspace> for local workspace paths.
