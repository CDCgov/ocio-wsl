# Releases

The `bump.yml` workflow publishes a patch release every Saturday at 08:17 UTC
(03:17 EST / 04:17 EDT), using `main`. You can also cut a release manually from
the Actions tab. Merging to `main` does not immediately publish a release.

## Cutting a release

1. Go to **Actions → Bump version → Run workflow** (on `main`)
2. Pick the semver level: `patch`, `minor`, or `major`
3. Run it

The workflow then:

1. Bumps `version` in `package.json` with `pnpm version <level>`
2. Runs `update-config.sh` to refresh `config/config.toml`, then runs the regression checks
3. Builds both `.wsl` images with `build.sh` and generates `checksums.txt` and `manifest.json`
4. Commits the version and tool config to `main` and pushes the tag (bare semver, e.g. `2.8.0`)
5. Creates the GitHub Release with auto-generated notes and attaches the images, checksums, and manifest

Release notes come from GitHub's own commit/PR summary (`gh release create --generate-notes`), so there is no `CHANGELOG.md` to maintain.

## Weekend updates and supply-chain protection

Each build pulls fresh base images and disables the build cache so the Dockerfile
package upgrades run again. This refreshes OS packages and installs the current
mise package from its signed apt/rpm repository. These packages follow repository
availability; the tool release delay below does not apply to OS packages or the
mise executable installed in the images.

The release workflow sets up mise with a 14-day minimum release age and no cache,
and uses it to install yq. The setup action verifies mise downloads against signed
checksums. Actions are pinned to commit SHAs.

`update-config.sh` explicitly passes the `minimum_release_age` from
`config/config.toml` (currently `14d`) to each `mise latest` lookup. Tool versions
therefore intentionally trail upstream releases. Failed or empty lookups keep the
existing pin and emit a warning; tool options and settings are preserved.

The [mise release-age policy](https://mise.jdx.dev/configuration/settings.html#minimum_release_age)
reduces exposure to newly compromised releases, but relies on backends providing
release dates. It is not a guarantee that every dependency is safe. Exact version
pins also bypass age filtering when installed; the delay is applied when resolving
updates. The config retains this policy for users' later version resolutions.

The release environment and its credentials must allow scheduled runs to push
to `main` and publish releases. Any environment
approval requirement still applies. Releases update downloadable images; existing
WSL installations are not patched automatically.

## Choosing a level

Nothing parses your commit messages, so the level is your call:

| Level   | Use it when                                                        |
| ------- | ------------------------------------------------------------------ |
| `patch` | Fixes, dependency and certificate updates, doc-only image rebuilds |
| `minor` | New tools in the image, new scripts, additive config changes       |
| `major` | Anything that breaks existing installs, e.g. dropping a distro     |

## Limitations

GitHub Releases have a [2 GB per-file limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas), which is why some tools are excluded from the base image and available via `mise upgrade` instead.

Because the images are built inside the bump workflow, a broken `Dockerfile` fails the run after the version has already been bumped locally in the job but before anything is pushed. Fix the build and run the workflow again; nothing is left behind on `main`.
