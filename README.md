# Windows Subsystem Build

This builds an Windows Subsystem Linux tar image for CDC as part of the developer experience.

## How to use this?

Make sure [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) is setup properly by opening powershell and typing `wsl`.

1. Download the [latest release](https://github.com/cdcent/ocio-wsl/releases).

2. Import a tar file and wait a bit.
   `wsl --import <distroName> <virtual hard disk> <tar file>`

3. Once imported, run the distro:
   `wsl -d <distroName>`

Example:

For the Ubuntu 22.04 distro, with a **virtual hard disk** path of **C:\Users\tpz7\ubuntu-22.04-vhd** and the tar file in **C:\Users\tpz7\Downloads\ubuntu-22.04-cdc:1.0-131020231108.tar**

`wsl --import ubuntu-22.04 C:\Users\tpz7\ubuntu-22.04-vhd C:\Users\tpz7\Downloads\ubuntu-22.04-cdc:1.0-131020231108.tar`

to run

`wsl -d ubuntu-22.04`

## WSL Tricks

To find out what distros are running, run `wsl --list --running`.

To shutdown WSL distros, run `wsl --shutdown` and [wait 8 seconds](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#the-8-second-rule).

When using `wsl --image` to run the image, it always logs you in [as the root user](https://learn.microsoft.com/en-us/windows/wsl/use-custom-distro#add-wsl-specific-components-like-a-default-user).

For whatever reason, occasionally if you run `wsl --shutdown`, you may end up crashing the Windows `vmcompute` service, so running `wsl` to log back into your default machine will incur a **Logon failure: the user has not been granted the requested logon type at this computer, with an error code of wsl/service/CreateInstance/CreateVm**. If that occurs, these are your actions to fix it without restarting.

1. Run `gpupdate /force` to ensure you're up to day with Group Policy settings with the rest of the Enterprise. This could take up to 10 minutes. This probably won't fix your problem either, but good to keep updated on your own terms. Continue on!
1. Find your -su user password and open an administrative powershell.
1. Restart the **vmcompute** service by running `Restart-Service vmcompute` in your admin powershell.
1. Try using `wsl` again.

## Local Testing

- Build the Container: `bash build.sh`

- Run a simple curl: `podman run -t ubuntu-22.04-cdc:1.0 bash -c "curl -vv google.com"`

## Issues

- Should I be using a dedicated user to install asdf?
  - [Example of adduser for asdf](https://github.com/webofmars/docker-asdf/blob/master/Dockerfile)
  - [Storing all asdf downloads into /opt](https://github.com/asdf-vm/asdf/issues/577)
- update-ca-certificates don't seem to update any certificates
  - Fixed - had to change the format of the file from .pem to a .crt for update-ca-certificates to pick it up.
- azure-cli with asdf can't install and won't run.

## Links to Follow

- https://github.com/mvaisakh/wsl-distro-tars
