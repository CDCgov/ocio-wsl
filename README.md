# CDC WSL Distribution

<div align="center">

[![latest tag](https://img.shields.io/github/v/tag/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
[![last release](https://img.shields.io/github/release-date/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
![total downloads](https://img.shields.io/github/downloads/cdcgov/ocio-wsl/total?style=for-the-badge)
![commit history](https://img.shields.io/github/commit-activity/y/cdcgov/ocio-wsl?label=commits&style=for-the-badge)
![build status](https://img.shields.io/github/actions/workflow/status/cdcgov/ocio-wsl/bump.yml?style=for-the-badge)

</div>

Pre-built [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) images for CDC developers. Common tools come pre-installed via [mise](https://mise.jdx.dev), and [enterprise certificates](https://github.com/CDCgov/ocio-certificates/blob/main/docs/technical.md) are already trusted so you don't have to fight with SSL certificate issues.

## Prerequisites

If `wsl` is already installed, you may skip these prerequisites.

Running `wsl --install` requires a Windows elevated privilege account. See [Prerequisites](docs/prerequisites.md) for how to request one.

## Installation

1. Open PowerShell with your normal account and confirm WSL2 is ready by running `wsl`. If it isn't, see [Prerequisites](docs/prerequisites.md) for how to request one.

2. Download the `.wsl` file for your preferred distro from the [latest release](https://github.com/cdcgov/ocio-wsl/releases/latest):

   | File                   | Distro       |
   | ---------------------- | ------------ |
   | `ubuntu-26.04-cdc.wsl` | Ubuntu 26.04 |
   | `fedora-44-cdc.wsl`    | Fedora 44    |

3. Install it:

   ```powershell
   wsl --install --from-file C:\Users\<username>\Downloads\ubuntu-26.04-cdc.wsl
   ```

   Or double-click the `.wsl` file in File Explorer.

4. Launch the distro. On first boot it will automatically create your user account and configure DNS.

## Linux workspace

First-login setup creates `~/code/cdc` on the WSL Linux filesystem. Keep your
repositories, virtual environments, and build output there for good I/O performance.

New interactive Bash shells start in `~/code/cdc` when launched from your Linux
home or a Windows drive under `/mnt`. Shells opened in an existing Linux project
keep that directory. Nested shells and non-interactive commands keep their
working directory too. If workspace setup has not finished, the shell keeps its
original directory.

For example:

```bash
cd ~/code/cdc
git clone git@github.com:CDCgov/ocio-wsl.git
cd ocio-wsl
```

Use a WSL-connected editor opened from this directory. To browse the current
directory in Windows File Explorer, run `explorer.exe .` from WSL.

`~/shared` links to your Windows profile's `wsl-shared` folder when Windows interop
is available during setup. Use it to transfer files between Windows and Linux.
If Windows is unavailable, setup creates a local `~/shared` directory instead.
A later setup run converts it to the Windows link if it is still empty. Existing
files and links are preserved.
Keep active repositories under `~/code/cdc`; `/mnt/c` remains available for Windows files.

For existing installations, workspace setup and repository migration instructions
are in [First-Time Setup](docs/first-time-setup.md#linux-workspace).

## Installed Tools

Tools are managed by [mise](https://mise.jdx.dev). mise itself is installed in the image, while each user gets an independent `~/.config/mise/config.toml` and tool directory. On first launch, the default tool list is copied into the user’s configuration; run `mise install` when you are ready to install the tools. The initial installation may take several minutes. To see what is installed:

```bash
mise list
```

To upgrade everything:

```bash
mise upgrade
```

To install a tool or change a version, edit your personal `~/.config/mise/config.toml`, then run `mise install` or `mise upgrade`.

Podman is installed as a base operating-system tool and is ready for rootless use by the default WSL user. The first-boot setup assigns subordinate UID/GID ranges and restores the mapping-helper privileges that may be lost while exporting and importing a WSL image. Verify it without `sudo`:

```bash
podman info --format '{{.Host.Security.Rootless}}'
podman run --rm quay.io/podman/hello
```

Find the full list of tools and their versions in the [config.toml file](https://github.com/CDCgov/ocio-wsl/blob/main/config/config.toml).

| Category  | Tools                                                 |
| --------- | ----------------------------------------------------- |
| Languages | Python, Node.js, Rust                                 |
| Cloud     | AWS CLI, Azure CLI, kubectl                           |
| Linting   | shellcheck, ruff, black, actionlint, semgrep, checkov |
| Utilities | ripgrep, csvlint, pre-commit, poetry, uv, pipx        |

## Extra Tools

Some tools are excluded from the base image due to a [2 GB GitHub release limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas). All of them are already listed in your `~/.config/mise/config.toml`, so running `mise upgrade` installs everything.

## Optional R Installation

R is not installed in the base image because the mise R plugin compiles R from source. Install the platform build dependencies first, then run this as your normal user:

```bash
mise use asdf:mise-plugins/mise-r --global
```

The image installs only the mise executable system-wide. Tool installations and the global configuration live in the user’s home directory. The image also trusts the CDC certificate bundle and activates mise in new Bash shells. These setup details matter here; the upstream one-line mise installer does not configure the enterprise certificate trust or the initial user tool setup.

R compilation defaults to one job in the plugin and can take a long time. Use all available CPUs when installing it:

```bash
ASDF_CONCURRENCY="$(nproc)" mise use asdf:mise-plugins/mise-r --global
```

For Fedora:

```bash
sudo dnf install -y libcurl-devel gcc-gfortran xz-libs bzip2-libs \
  libX11-devel libXt-devel xorg-x11-proto-devel pcre2-devel
```

For Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y build-essential libcurl4-openssl-dev gfortran \
  liblzma-dev liblzma5 libbz2-dev libbz2-1.0 xorg-dev libpcre2-dev
```

Verify the installation with:

```bash
R --version | head -1
mise ls
```

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

Run the isolated startup regression checks without a container:

```bash
uv sync --locked
uv run --locked pytest -q
```

The test environment uses Python from `.python-version` and the dependency
versions in `uv.lock`. Use uv 0.13.1 or newer; CI installs the latest uv release.
`--locked` fails if the project and lockfile are out of sync. To update dependencies deliberately, run `uv lock --upgrade`
and commit the updated lockfile.

The checks exercise failure and recovery paths using temporary account and path
fixtures. Full OOBE, systemd startup ([config/run-once.service](config/run-once.service)),
and WSL-managed DNS still require testing both images on Windows.

For a quick build-test-cleanup loop:

```bash
bash build.sh fedora && bash test.sh fedora && bash cleanup.sh fedora
```

## Documentation

- [Prerequisites](docs/prerequisites.md) on elevated privilege account, WSL2 setup
- [First-Time Setup](docs/first-time-setup.md) accounts for user creation, DNS configuration
- [WSL Tips and Troubleshooting](docs/wsl-tricks.md) gives us common commands, vmcompute crash fix
- [Releases](docs/releases.md) shows how versioning and CI releases work
