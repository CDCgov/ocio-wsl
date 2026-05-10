# Releases

Releases are automated using [Semantic Release](https://github.com/semantic-release/semantic-release) and driven by [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Commit prefixes

| Prefix                            | Version bump | Example                                |
| --------------------------------- | ------------ | -------------------------------------- |
| `fix:`                            | patch        | `fix: resolve DNS on fresh install`    |
| `feat:`                           | minor        | `feat: add terraform to default tools` |
| `feat!:` / `fix!:` / `refactor!:` | major        | `feat!: drop Ubuntu 22.04 support`     |

The `!` suffix (or a `BREAKING CHANGE:` footer) triggers a major bump regardless of the prefix.

See the [commit-analyzer default rules](https://github.com/semantic-release/commit-analyzer/blob/master/lib/default-release-rules.js) for the full list of recognized prefixes.

## On Release

1. CI runs the deploy workflow on merge to `main`
2. `@semantic-release/commit-analyzer` reads commits since the last tag and calculates the next version
3. `@semantic-release/npm` updates `version` in `package.json` (no npm publish)
4. `@semantic-release/git` commits `package.json` and `CHANGELOG.md` back to `main`
5. `@semantic-release/github` creates a GitHub Release and attaches the `.wsl` image artifacts

## Limitations

GitHub Releases have a [2 GB per-file limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas), which is why some tools are excluded from the base image and available via `mise upgrade` or `bash /opt/scripts/add-extra-tools.sh` instead.
