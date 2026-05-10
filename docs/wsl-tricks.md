# WSL Tips and Troubleshooting

## Common commands

| Task                        | Command                                       |
| --------------------------- | --------------------------------------------- |
| List running distros        | `wsl --list --running`                        |
| List all distros            | `wsl --list --verbose`                        |
| Shut down all distros       | `wsl --shutdown`                              |
| Terminate a specific distro | `wsl --terminate <distroName>`                |
| Enter a specific distro     | `wsl -d <distroName>`                         |
| Browse distro filesystem    | `wsl -d <distro>` → `cd ~` → `explorer.exe .` |

After `wsl --shutdown`, [wait 8 seconds](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#the-8-second-rule) before relaunching.

## vmcompute crash after `wsl --shutdown`

Occasionally `wsl --shutdown` crashes the Windows `vmcompute` service, producing:

> **Logon failure: the user has not been granted the requested logon type at this computer**  
> Error code: `wsl/service/CreateInstance/CreateVm`

Fix (no restart required):

1. _(Optional)_ Run `gpupdate /force` in an admin PowerShell to sync Group Policy.
2. Open an admin PowerShell using your `-su` account (find the password in [CyberArk](https://cyber.cdc.gov)).
3. Run `Restart-Service vmcompute`.
4. Try `wsl` again.

## Navigating the distro filesystem from Windows

Open File Explorer and go to `\\wsl$\` to browse all installed distro filesystems directly.

## Further reading

- [Microsoft WSL Troubleshooting](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting)
- [mvaisakh/wsl-distro-tars](https://github.com/mvaisakh/wsl-distro-tars) illustrates how WSL tar images are built
