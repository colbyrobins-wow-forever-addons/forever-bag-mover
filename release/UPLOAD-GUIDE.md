# CurseForge upload kit

Current prepared release: **0.8.0**. Follow `../DEVELOPMENT.md` for development,
in-game acceptance, and release preparation. Public upload is a separate step.

## Automated upload

Pushing a `v<version>` tag runs `.github/workflows/ci-release.yml`. After checks
and version/changelog validation, it creates the GitHub Release and packages
`ForeverBagMover-v<version>-forever.zip` using `changelog-<version>.md`.
CurseForge upload needs the `CF_API_TOKEN` repository secret and the TOC's
`## X-Curse-Project-ID: 1702198`; without the secret the workflow warns and
skips that upload.

Tag pushes are publication, so never push a tag during release preparation.
For a manual upload, build the ZIP from the tag as described in
`../WOW-ADDON-PRACTICES.md` (Release gate, step 7).

## Project fields

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Name | Forever Bag Mover |
| CurseForge project ID | 1702198 |
| Summary | Arrange individual or combined bags with preview, save, and cancel. |
| Project class | Addons |
| Main category | Bags & Inventory |
| Logo | `../screenshots/forever-bag-mover.png` |
| Description | Paste `curseforge-description.md` using Markdown mode |
| License | Keep the project's existing license; none is chosen here. |
| Source / issues | https://github.com/colbyrobins-wow-forever-addons/forever-bag-mover ; issues at `/issues` |
| Dependencies | None |

## File upload fields

- File: the packaged ZIP (automated) or `dist/ForeverBagMover-<version>.zip` (manual).
- Display name: `Forever Bag Mover <version> — Forever`.
- Game flavor: **Forever**; game version **1.60.1** (interface 16001). Never
  substitute Retail or Classic Era.
- Release type: **Release**.
- Changelog: `changelog-<version>.md`.

## Submission steps (manual upload)

1. Open the existing Forever Bag Mover project in the CurseForge author dashboard.
2. Update the description from `curseforge-description.md` if features changed.
3. Open Files, upload the ZIP with the fields above, and submit for moderation.

## Optional screenshots

Use real in-game captures only (see `../screenshots/`), never mockups.

## Copy-ready upload assistant prompt

```text
Help me update the existing CurseForge World of Warcraft addon project "Forever Bag Mover" (project ID 1702198) to version <version>. Use release/UPLOAD-GUIDE.md, release/curseforge-description.md, and release/changelog-<version>.md. Upload dist/ForeverBagMover-<version>.zip, select Forever / 1.60.1 only, release type Release, no dependencies, and keep the existing license. Do not claim Retail or Classic Era compatibility. Prepare all fields for review and stop before final public submission.
```

## Announcement copy

```text
Forever Bag Mover 0.8.0 for WoW Forever adds a minimap button that opens the settings panel, plus an option to hide the padlock and filter buttons on your bags (/fbm buttons hide). Available on CurseForge: [paste project link]
```

## References

- https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project
- https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips
