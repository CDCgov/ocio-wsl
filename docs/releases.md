# Releases

Releases are cut manually from the Actions tab. There is no automatic release on merge to `main` — merging is safe, and nothing ships until someone runs the bump.

## Cutting a release

1. Go to **Actions → Bump version → Run workflow** (on `main`)
2. Pick the semver level: `patch`, `minor`, or `major`
3. Run it

The workflow then:

1. Bumps `version` in `package.json` with `pnpm version <level>`
2. Builds both `.wsl` images with `build.sh` and generates `checksums.txt` and `manifest.json`
3. Commits the bump to `main` and pushes the tag (bare semver, e.g. `2.8.0`)
4. Creates the GitHub Release with auto-generated notes and attaches the images, checksums, and manifest

Release notes come from GitHub's own commit/PR summary (`gh release create --generate-notes`), so there is no `CHANGELOG.md` to maintain.

## Choosing a level

Nothing parses your commit messages, so the level is your call:

| Level   | Use it when                                                        |
| ------- | ------------------------------------------------------------------ |
| `patch` | Fixes, dependency and certificate updates, doc-only image rebuilds |
| `minor` | New tools in the image, new scripts, additive config changes       |
| `major` | Anything that breaks existing installs, e.g. dropping a distro     |

## Limitations

GitHub Releases have a [2 GB per-file limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas), which is why some tools are excluded from the base image and available via `mise upgrade` or `bash /opt/scripts/add-extra-tools.sh` instead.

Because the images are built inside the bump workflow, a broken `Dockerfile` fails the run after the version has already been bumped locally in the job but before anything is pushed. Fix the build and run the workflow again; nothing is left behind on `main`.
