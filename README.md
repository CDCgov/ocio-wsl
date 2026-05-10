# CDC WSL Distribution

<div align="center">

[![semantic-release: conventional-commit](https://img.shields.io/badge/semantic--release-conventionalcommit-e10079?logo=semantic-release&style=for-the-badge)](https://github.com/semantic-release/semantic-release)
[![latest tag](https://img.shields.io/github/v/tag/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
[![last release](https://img.shields.io/github/release-date/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
![total downloads](https://img.shields.io/github/downloads/cdcgov/ocio-wsl/total?style=for-the-badge)
![commit history](https://img.shields.io/github/commit-activity/y/cdcgov/ocio-wsl?label=commits&style=for-the-badge)
![deploy status](https://img.shields.io/github/actions/workflow/status/cdcgov/ocio-wsl/deploy.yml?style=for-the-badge)

</div>

Pre-built [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) images for CDC developers. Common tools come pre-installed via [mise](https://mise.jdx.dev), and [enterprise certificates](https://github.com/CDCgov/ocio-certificates/blob/main/docs/technical.md) are already trusted so you can hit internal sites without fighting SSL errors.

## Prerequisites

If `wsl` is already installed, you may skip these prerequisites.

Running `wsl --install` requires a Windows elevated privilege account. See [Prerequisites](docs/prerequisites.md) for how to request one.

## Installation

Before starting, make sure you have an elevated privilege (`-su`) account and WSL2 installed and updated. See [Prerequisites](docs/prerequisites.md) if this is a new computer.

1. Open PowerShell using your `-su` account and confirm WSL2 is ready by running `wsl`.

2. Download the `.wsl` file for your preferred distro from the [latest release](https://github.com/cdcgov/ocio-wsl/releases/latest):

   | File                   | Distro       |
   | ---------------------- | ------------ |
   | `ubuntu-24.04-cdc.wsl` | Ubuntu 24.04 |
   | `fedora-43-cdc.wsl`    | Fedora 43    |

3. Install it:

   ```powershell
   wsl --install --from-file C:\Users\<username>\Downloads\ubuntu-24.04-cdc.wsl
   ```

   Or double-click the `.wsl` file in File Explorer.

4. Launch the distro. On first boot it will automatically create your user account and configure DNS.

## Installed Tools

Tools are managed by [mise](https://mise.jdx.dev) and configured in `/etc/mise/config.toml`. To see what's installed:

```bash
mise list
```

To upgrade everything:

```bash
mise upgrade
```

To install a tool or change a version, edit `/etc/mise/config.toml` or your personal `~/.config/mise/config.toml`, then run `mise upgrade`.

### Pre-installed Tools

| Category  | Tools                                                 |
| --------- | ----------------------------------------------------- |
| Languages | Python 3.13, Node.js, Go, Java, R, Rust               |
| Cloud     | AWS CLI, Azure CLI, kubectl, Helm, Terraform          |
| Build     | Gradle, Maven                                         |
| Linting   | shellcheck, ruff, black, actionlint, semgrep, checkov |
| Utilities | ripgrep, grype, pre-commit, poetry, uv, pipx          |

## Extra Tools

Some tools are excluded from the base image due to a [2 GB GitHub release limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas). All of them are already listed in `/etc/mise/config.toml`, so running `mise upgrade` should install everything. If you run into ordering or timeout issues (particularly with Rust behind Zscaler), use the helper script instead:

```bash
bash /opt/scripts/add-extra-tools.sh
```

The script installs foundational tools (Node.js, Java, Go, R, Rust) in the correct order before running `mise upgrade` for the rest.

## Local Development

Build a specific distro image locally:

```bash
bash build.sh ubuntu   # builds ubuntu-24.04-cdc
bash build.sh fedora   # builds fedora-43-cdc
```

Run a quick test against the built image:

```bash
podman run -t ubuntu-24.04-cdc bash -c "bash /opt/scripts/check-google.sh"
```

To debug an image interactively, build it and exec in:

```bash
bash build.sh fedora && bash test.sh
podman exec -it fedora-43-cdc-test bash
```

Note that startup sequences like DNS setup ([config/run-once.service](config/run-once.service)) only run under WSL, so testing those requires a real Windows install.

For a quick build-test-cleanup loop:

```bash
bash build.sh fedora && bash test.sh fedora && bash cleanup.sh fedora
```

## Documentation

- [Prerequisites](docs/prerequisites.md) on elevated privilege account, WSL2 setup
- [First-Time Setup](docs/first-time-setup.md) accounts for user creation, DNS configuration
- [WSL Tips and Troubleshooting](docs/wsl-tricks.md) gives us common commands, vmcompute crash fix
- [Releases](docs/releases.md) shows how versioning and CI releases work
