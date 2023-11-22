# Windows Subsystem Build

![deploy badge](https://github.com/cdcent/ocio-wsl/actions/workflows/distro.yml/badge.svg)

This builds an Windows Subsystem Linux (WSL) tarball image for CDC as part of the developer experience.

## Prerequisities

For requirements and prerequisities, go to [docs/prerequisities.md](docs/prerequisites.md).

## How to use this?

Make sure [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) is setup properly by opening powershell and typing `wsl`.

**Note**: when running `wsl` for the first time, WSL will require administrative rights using your -su account in powershell. The username is your 4 letter user name + `-su` (ex. tpz7-su) and the password is in [CyberArk](https://cyber.cdc.gov).

1. Download the [latest release](https://github.com/cdcent/ocio-wsl/releases/latest).

2. Import a tar file and wait a bit.
   `wsl --import <distroName> <virtual hard disk> <tar file>`

3. Once the distro has been imported, DNS resolution does not yet work! Download this [fix-dns.ps1 powershell script](./scripts/fix-dns.ps1) and run it by running `powershell -executionpolicy bypass -File fix-dns.ps1 <distro_name>`.

4. Set it as the default distro:
   `wsl --set-default <distroName>`

5. Once imported, run the distro:
   `wsl` or `wsl -d <distroName>`

Example:

For the Ubuntu 22.04 distro, with a **virtual hard disk** path of **C:\Users\tpz7\ubuntu-22.04-vhd** and the tar file in **C:\Users\tpz7\Downloads\ubuntu-22.04-cdc.tar**

1. `wsl --import ubuntu-22.04-cdc C:\Users\tpz7\ubuntu-22.04-vhd C:\Users\tpz7\Downloads\ubuntu-22.04-cdc.tar`

2. Fix the DNS: `powershell -executionpolicy bypass -File fix-dns.ps1 ubuntu-22.04-cdc`.

3. Run the distro: `wsl -d ubuntu-22.04-cdc`

## Installing Extra Tools

Inside the image, the /opt/scripts folder has a script to install [an additional list](./scripts/add-extra-tools.sh) of tools.

To install this list of tools, run `bash /opt/scripts/add-extra-tools.sh`. We couldn't fit it all into the image due to a [2GB restriction](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas).

## Change Tool versions

We utilize [asdf](https://asdf-vm.com/) to install common programming tools and it comes with a [tool versions file](./config/.tool-versions).

To update or change the version of [these tools](./config/.tool-versions), change the version of the tool in the file; ex. python 3.11.6, save the file, and run `asdf install`.

Once it is completed, you can run `python -v` with python 3.11.6.

Use `asdf list-all python` to figure out the available versions of python you can install.

## WSL Tricks

To find out what distros are running, run `wsl --list --running`.

To shutdown WSL distros, run `wsl --shutdown` and [wait 8 seconds](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#the-8-second-rule).

When using `wsl --image` to run the image, it always logs you in [as the root user](https://learn.microsoft.com/en-us/windows/wsl/use-custom-distro#add-wsl-specific-components-like-a-default-user).

For whatever reason, occasionally if you run `wsl --shutdown`, you may end up crashing the Windows `vmcompute` service, so running `wsl` to log back into your default machine will incur a **Logon failure: the user has not been granted the requested logon type at this computer, with an error code of wsl/service/CreateInstance/CreateVm**. If that occurs, these are your actions to fix it without restarting.

1. Run `gpupdate /force` to ensure you're up to day with Group Policy settings with the rest of the Enterprise. This could take up to 10 minutes. This probably won't fix your problem either, but good to keep updated on your own terms. Continue on!
1. Find your -su user password and open an administrative powershell.
1. Restart the **vmcompute** service by running `Restart-Service vmcompute` in your admin powershell.
1. Try using `wsl` again.

It is possible to navigate the filesystem of the distro by going to \\wsl$\ and finding the distribution folder using Windows. Otherwise, one quick way to access it is to `wsl -d <distro>` and go to the root `cd ~` and then run `explorer.exe .`, a Window will pop up going to the filesystem.

## Local Testing

- Build the Container: `bash build.sh`

- Run a simple curl: `podman run -t ubuntu-22.04-cdc bash -c "curl -vv google.com"`

- Check whether going to google.com works: `podman run -t ubuntu-22.04-cdc bash -c "bash /opt/scripts/check-google.sh"`

- Download additional software: `podman run -t ubuntu-22.04-cdc bash -c "bash /opt/scripts/add-extra-tools.sh"`

## Releases

We utilize [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) messages and automated tagging via Semantic Versioning.

The most important prefixes you should have in mind when writing git commit messages are:

    fix: which represents bug fixes, and correlates to a SemVer patch.
    feat: which represents a new feature, and correlates to a SemVer minor.
    feat!:, or fix!:, refactor!:, etc., which represent a breaking change (indicated by the !) and will result in a SemVer major.

## Issues

- Should I be using a dedicated user to install asdf?
  - [Example of adduser for asdf](https://github.com/webofmars/docker-asdf/blob/master/Dockerfile)
  - [Storing all asdf downloads into /opt](https://github.com/asdf-vm/asdf/issues/577)
- update-ca-certificates don't seem to update any certificates
  - Fixed - had to change the format of the file from .pem to a .crt for update-ca-certificates to pick it up.
- azure-cli with asdf can't install and won't run.
  - Fixed - needed to install Python and use a ~/.tool-versions file to install.
- Github Releases per file has a [upper limit of 2GB](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas).
  - Sort of fixed - slim down the image.

## Links to Follow

- [mvaisakh/wsl-distro-tars](https://github.com/mvaisakh/wsl-distro-tars)
