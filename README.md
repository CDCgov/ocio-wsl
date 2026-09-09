# CDC WSL Distribution

<div align="center">

[![semantic-release: conventional-commit](https://img.shields.io/badge/semantic--release-conventionalcommit-e10079?logo=semantic-release&style=for-the-badge)](https://github.com/semantic-release/semantic-release)
[![latest tag](https://img.shields.io/github/v/tag/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
[![last release](https://img.shields.io/github/release-date/cdcgov/ocio-wsl?style=for-the-badge)](https://github.com/cdcgov/ocio-wsl/releases)
![total downloads](https://img.shields.io/github/downloads/cdcgov/ocio-wsl/total?style=for-the-badge)
![commit history](https://img.shields.io/github/commit-activity/y/cdcgov/ocio-wsl?label=commits&style=for-the-badge)
![deploy status](https://img.shields.io/github/actions/workflow/status/cdcgov/ocio-wsl/deploy.yml?style=for-the-badge)

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
   | `ubuntu-24.04-cdc.wsl` | Ubuntu 24.04 |
   | `fedora-43-cdc.wsl`    | Fedora 43    |

3. Install it:

   ```powershell
   wsl --install --from-file C:\Users\<username>\Downloads\ubuntu-24.04-cdc.wsl
   ```

   Or double-click the `.wsl` file in File Explorer.

4. Launch the distro. On first boot it will automatically create your user account and configure DNS.

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

Azure CLI uses the CDC-maintained `asdf:boris-ning-usds/asdf-azure-cli` fork. The fork avoids the upstream plugin's restrictive Python-version behavior and creates an independent virtual environment for Azure CLI. The fork should create that environment with `python3 -m venv --copies` so a later mise Python upgrade cannot remove its interpreter. Do not also declare the native `azure-cli` backend; two entries can create conflicting `az` launchers.

The custom Azure CLI plugin owns its private Python environment. Azure CLI extensions, including `resource-graph`, use that private interpreter and do not depend on the separately managed user Python.

Podman is installed as a base operating-system tool and is ready for rootless use by the default WSL user. The first-boot setup assigns subordinate UID/GID ranges and restores the mapping-helper privileges that may be lost while exporting and importing a WSL image. Verify it without `sudo`:

```bash
podman info --format '{{.Host.Security.Rootless}}'
podman run --rm quay.io/podman/hello
```

Find the full list of tools and their versions in the [config.toml file](https://github.com/CDCgov/ocio-wsl/blob/main/config/config.toml).

| Category  | Tools                                                 |
| --------- | ----------------------------------------------------- |
| Languages | Python 3.13, Node.js, Go, Java, Rust                  |
| Cloud     | AWS CLI, Azure CLI, kubectl, Helm, Terraform          |
| Build     | Gradle, Maven                                         |
| Linting   | shellcheck, ruff, black, actionlint, semgrep, checkov |
| Utilities | ripgrep, grype, pre-commit, poetry, uv, pipx          |

## Extra Tools

Some tools are excluded from the base image due to a [2 GB GitHub release limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas). All of them are already listed in your `~/.config/mise/config.toml`, so running `mise upgrade` should install everything. If you run into ordering or timeout issues (particularly with Rust behind Zscaler), use the helper script instead:

```bash
bash /opt/scripts/add-extra-tools.sh
```

The script installs foundational tools (Node.js, Java, Go, Rust) in the correct order before running `mise upgrade` for the rest.

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

If upgrading an existing image left `az` broken, remove the native `azure-cli` entry from `~/.config/mise/config.toml`, use the custom fork, and reinstall it:

```bash
mise uninstall azure-cli@2.85.0 || true
mise use --global 'asdf:boris-ning-usds/asdf-azure-cli@2.85.0'
mise install
az --version
```

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
