# CDC WSL Distribution

<div align="center">

[![latest tag](https://img.shields.io/github/v/tag/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
[![last release](https://img.shields.io/github/release-date/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
![total downloads](https://img.shields.io/github/downloads/cdcgov/ocio-wsl/total?style=for-the-badge)
![commit history](https://img.shields.io/github/commit-activity/y/cdcgov/ocio-wsl?label=commits&style=for-the-badge)
![build status](https://img.shields.io/github/actions/workflow/status/cdcgov/ocio-wsl/bump.yml?style=for-the-badge)

</div>

This project grew out of my frustration with setting up a new development environment in government: every setup was a little different, TLS certificates were a constant fight, and running Linux on Windows brought its own headaches. It provides pre-built [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) Linux images for CDC developers. Common tools are ready to install with [mise](https://mise.jdx.dev), and the [enterprise certificates](https://github.com/CDCgov/ocio-certificates/blob/main/docs/technical.md) are already trusted, so we don't have to fight certificate errors anymore.

## Prerequisites

Installing [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/about) requires a Windows **elevated privilege** account. If `wsl` is already installed, you can skip this. Otherwise, see [Prerequisites](docs/prerequisites.md) for how to request the account and enable WSL2.

## Installation

1. Open PowerShell with your normal account and run `wsl` to confirm WSL2 is ready. If it isn't, follow [Prerequisites](docs/prerequisites.md).

2. Download the `.wsl` file for your preferred distro from the [latest release](https://github.com/cdcgov/ocio-wsl/releases/latest):

   | File                   | Distro       |
   | ---------------------- | ------------ |
   | `ubuntu-26.04-cdc.wsl` | Ubuntu 26.04 |
   | `fedora-44-cdc.wsl`    | Fedora 44    |

3. Install it by double-clicking the `.wsl` file in File Explorer. If you prefer the command line, run this in PowerShell:

   ```powershell
   wsl --install --from-file C:\Users\<username>\Downloads\ubuntu-26.04-cdc.wsl
   ```

4. Launch the distro. On first boot it creates your user account and configures DNS automatically. See [First-Time Setup](docs/first-time-setup.md) for what happens behind the scenes.

## Linux workspace

First login creates `~/code/cdc` on the Linux filesystem, and new shells start there. Keep your repositories, virtual environments, and build output in it for good I/O performance; `/mnt/c` is still available for Windows files.

```bash
cd ~/code/cdc
git clone git@github.com:CDCgov/ocio-wsl.git
cd ocio-wsl
```

Open your editor through its WSL connection from this directory. To browse the current directory in Windows File Explorer, run `explorer.exe .`. To move files between Windows and Linux, use `~/shared`, which links to `%USERPROFILE%\wsl-shared` on Windows.

If you're upgrading an existing installation or moving repositories off `/mnt/c`, see [First-Time Setup](docs/first-time-setup.md#linux-workspace).

## Tools

The image installs only mise itself. Each user gets their own `~/.config/mise/config.toml` and tool directory, seeded with the default tool list on first launch. Keeping tools out of the image keeps it under GitHub's [2 GB release file limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas).

When you're ready, install everything (the first run can take several minutes):

```bash
mise install
```

| Category  | Tools                                                 |
| --------- | ----------------------------------------------------- |
| Languages | Python, Node.js, Rust                                 |
| Cloud     | AWS CLI, Azure CLI, kubectl                           |
| Linting   | shellcheck, ruff, black, actionlint, semgrep, checkov |
| Utilities | ripgrep, csvlint, pre-commit, poetry, uv, pipx        |

The full list with versions is in [config/config.toml](config/config.toml). Use `mise list` to see what's installed and `mise upgrade` to update everything. To add a tool or change a version, edit your `~/.config/mise/config.toml` and run `mise install`.

Use the system mise rather than the upstream one-line installer. The image's setup also trusts the CDC certificate bundle and activates mise in new Bash shells, which the upstream installer doesn't do.

[Podman](https://podman.io) is installed as an OS package and works rootless for your default user, no `sudo` needed. See [First-Time Setup](docs/first-time-setup.md#rootless-podman) to verify or repair it.

R isn't in the default tool list because it compiles from source. See [Installing R](docs/r-installation.md) if you need it.

## Local Development

Build a specific distro image locally:

```bash
bash build.sh ubuntu   # builds ubuntu-26.04-cdc
bash build.sh fedora   # builds fedora-44-cdc
```

Run a quick test against the built image:

```bash
podman run -t ubuntu-26.04-cdc bash -c "bash /opt/scripts/check-google.sh"
```

To debug an image interactively, build it and exec in:

```bash
bash build.sh fedora && bash test.sh
podman exec -it fedora-44-cdc-test bash
```

For a quick build-test-cleanup loop:

```bash
bash build.sh fedora && bash test.sh fedora && bash cleanup.sh fedora
```

Run the startup regression checks without a container:

```bash
uv sync --locked
uv run --locked pytest -q
```

The tests use the Python version in `.python-version` and the dependencies in `uv.lock`. Use uv 0.13.1 or newer; CI installs the latest release. `--locked` fails if the project and lockfile are out of sync. To update dependencies deliberately, run `uv lock --upgrade` and commit the updated lockfile.

The checks exercise failure and recovery paths using temporary account and path fixtures. Full OOBE, systemd startup ([config/run-once.service](config/run-once.service)), and WSL-managed DNS still need to be tested on Windows with both images.

## Documentation

- [Prerequisites](docs/prerequisites.md): requesting an elevated privilege account and enabling WSL2.
- [First-Time Setup](docs/first-time-setup.md): what runs on first boot (user account, DNS, Podman, workspace), GitHub SSH setup, and how to fix setup that didn't finish.
- [Installing R](docs/r-installation.md): build dependencies and the mise command for compiling R.
- [WSL Tips and Troubleshooting](docs/wsl-tricks.md): everyday `wsl` commands and the fix for the `vmcompute` crash after `wsl --shutdown`.
- [Releases](docs/releases.md): how weekly and manual releases are built, versioned, and protected against compromised upstream releases.
