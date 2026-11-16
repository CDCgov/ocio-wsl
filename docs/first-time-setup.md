# First-Time Setup

This page explains how the initial setup is automated. You don't need to follow it unless something went wrong with the image.

When you first launch the distro, these steps run automatically:

- **DNS configuration**: WSL generates `/etc/resolv.conf` from Windows networking. User setup doesn't overwrite it, so WSL DNS tunneling remains available.
- **User creation**: creates a non-root account (UID 1000) named after your Windows username, lowercased with unsupported characters removed (for example, `First.Last` becomes `firstlast`), and grants it `sudo` access. When you install with `wsl --install`, the out-of-box setup (`/etc/oobe.sh`) handles this and prompts for a name if it can't read your Windows username. When you use `wsl --import`, the startup service creates the account instead. Both use `/opt/scripts/create-default-user.sh`, so you only ever get one account.
- **Rootless Podman**: assigns subordinate UID/GID ranges and restores the user-namespace helper privileges that can be lost when a WSL image is exported and imported.
- **Linux workspace**: creates `~/code/cdc` for repositories and, when Windows is reachable, `~/shared` for transferring files.

## Linux workspace

Run development tools from `~/code/cdc` on the Linux filesystem. mise already keeps each user's tools and cache in their Linux home directory.

New interactive Bash shells start in `~/code/cdc` when launched from your Linux home directory or a Windows drive under `/mnt`. Shells opened in an existing Linux project, nested shells, and non-interactive commands keep their working directory. If `~/code/cdc` doesn't exist yet, the shell stays in its original directory until workspace setup finishes.

`~/shared` links to `%USERPROFILE%\wsl-shared` on Windows when Windows interop is available during setup. If it isn't, setup creates a local `~/shared` directory instead. Use it for file transfers, and keep repositories and build output under `~/code/cdc`.

To create the workspace on an existing installation with the updated scripts:

```bash
sudo /opt/scripts/setup-user-workspace.sh "$USER"
cd ~/code/cdc
```

If you're applying the change from this repository instead of a new image, run `sudo bash scripts/setup-user-workspace.sh "$USER"` from the repository root.

Rerunning the helper replaces an empty local `~/shared` directory with the Windows link once Windows is available. Directories that contain files, and existing links, are left alone; move your local files elsewhere before retrying if you want the link.

### Moving a repository off Windows storage

To copy an existing checkout from Windows storage, first stop any tools that write to it, then copy it to an unused destination name:

```bash
test ! -e ~/code/cdc/ocio-wsl && \
  rsync -a /mnt/c/Users/<username>/code/cdc/ocio-wsl/ ~/code/cdc/ocio-wsl/
cd ~/code/cdc/ocio-wsl
git status
```

The copy preserves Git history, local changes, and untracked files. Keep the original until you've verified the Linux checkout. For other projects, recreate dependencies and virtual environments in the new location if they contain absolute paths or platform-specific binaries. Then reopen your editor using its WSL connection to the Linux checkout.

## Rootless Podman

Run Podman as your normal user; `sudo` is not required:

```bash
podman info --format '{{.Host.Security.Rootless}}'
podman run --rm quay.io/podman/hello
```

The first command should print `true`. If it doesn't, repair the current user and retry:

```bash
sudo /opt/scripts/configure-rootless-podman.sh "$USER"
podman system migrate
```

## GitHub SSH setup

The first-login banner includes these commands. To connect to GitHub over SSH:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -o -a 100 -C "you@example.com" -f ~/.ssh/github_ed25519
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_ed25519
clip.exe < ~/.ssh/github_ed25519.pub
```

Open [GitHub SSH keys](https://github.com/settings/keys), select **New SSH key**, and paste the copied public key. Test the connection with:

```bash
ssh -T git@github.com
```

`ssh-keygen` asks for a passphrase and creates an ED25519 key in OpenSSH's encrypted private-key format with a high key-derivation work factor. The private key stays in `~/.ssh/github_ed25519`; only the `.pub` file should be added to GitHub.

For a dedicated GitHub SSH configuration, add this to `~/.ssh/config`:

```sshconfig
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/github_ed25519
    IdentitiesOnly yes
```

Protect the configuration with `chmod 600 ~/.ssh/config`. If you use multiple GitHub accounts, give each account a separate `Host` alias and key instead of reusing this entry. Newer OpenSSH versions may also support post-quantum key exchange; check with `ssh -Q kex | grep -E '(mlkem|sntrup)'` before configuring it.

## If the default user is still root after first login

Check `sudo systemctl status run-once.service` and `sudo journalctl -u run-once.service`. Setup allows six start attempts until the distro restarts or the service is reset. Each attempt has a 30-second startup timeout and a 5-second shutdown timeout, and persistent failures remain visible. Windows username and profile detection each have a 5-second timeout, followed by forced termination after another 2 seconds if needed. Waiting for another account setup process is limited to 35 seconds.

A tool setup failure doesn't block recording the default user or attempting the remaining setup steps. Interrupted password initialization is tracked under `/var/lib/cdc-wsl`, so it can resume for the account created by setup. Passwords on established accounts, including passwords set after an interrupted attempt, are preserved.

If you used `wsl --import` and Windows username detection keeps failing, run this as root, replacing `myuser` with your preferred UNIX username:

```bash
/opt/scripts/create-default-user.sh myuser
systemctl reset-failed run-once.service
systemctl restart run-once.service
```

Once the account exists, rerunning the helper finishes its setup. OOBE reports setup failures for an existing account without prompting for another username.

To force a restart immediately, run `wsl --terminate <distroName>` from a Windows terminal, then log back in.

To make root the default user again, change the `default` entry in `/etc/wsl.conf` to `root`, then terminate and restart the distro.

## If DNS is not resolving

New images use `generateResolvConf = true` in `/etc/wsl.conf`. WSL owns the resolver file; the startup service doesn't copy DNS server addresses from Windows. See [Microsoft's WSL configuration reference](https://learn.microsoft.com/en-us/windows/wsl/wsl-config) for DNS generation and tunneling settings.

For an existing installation with the old configuration:

1. Set `generateResolvConf = true` under `[network]` in `/etc/wsl.conf`.
2. If you previously made `/etc/resolv.conf` immutable, remove that attribute with `sudo chattr -i /etc/resolv.conf`.
3. Terminate the distro from Windows with `wsl --terminate <distroName>`, then launch it again so WSL regenerates the resolver file.

Check `cat /etc/resolv.conf` and `getent hosts github.com`. If resolution still fails, check Windows networking and VPN connectivity. Don't overwrite the generated resolver file by hand; those edits are lost when WSL regenerates it.
