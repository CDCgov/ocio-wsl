# First-Time Setup

This serves just a simple knowledge base on how we automated the initial setup sequence, it's not meant to be followed unless something wrong happened with the image.

When you first launch the distro, these steps run automatically:

- **DNS configuration** - WSL generates `/etc/resolv.conf` from Windows networking. User setup does not overwrite it, so WSL DNS tunneling remains available.
- **User creation** - creates a non-root account (UID 1000) named after your Windows username, lowercased with unsupported characters removed (for example `First.Last` becomes `firstlast`), and grants it `sudo` access. When you install with `wsl --install`, the out-of-box setup (`/etc/oobe.sh`) handles this and prompts for a name if it cannot read your Windows username. When you use `wsl --import`, the startup service creates the account instead. Both use `/opt/scripts/create-default-user.sh`, so you only ever get one account.
- **Rootless Podman** - assigns subordinate UID/GID ranges and repairs the user-namespace helpers after WSL image import
- **Linux workspace** - creates `~/code/cdc` for repositories and `~/shared` for transferring files to Windows when available

You do not need to do anything manually for these steps.

## Linux workspace

Run development tools from `~/code/cdc` on the Linux filesystem. Mise already keeps
each user's tools and cache in their Linux home directory by default.

The image's Bash startup configuration selects `~/code/cdc` for new interactive
shells launched from the Linux home directory or a Windows drive under `/mnt`.
Existing Linux project directories, nested shells, and non-interactive commands
retain their working directory. If `~/code/cdc` does not exist yet, the shell
keeps its original directory until workspace setup finishes.

To create the workspace on an existing installation with the updated scripts:

```bash
sudo /opt/scripts/setup-user-workspace.sh "$USER"
cd ~/code/cdc
```

If you are applying the change from this repository instead of a new image, run
`sudo bash scripts/setup-user-workspace.sh "$USER"` from the repository root.
When rerun, the helper replaces an empty local `~/shared` directory with the Windows
link if Windows becomes available. Directories containing files and existing links
are preserved; move your local files elsewhere before retrying if you want the link.

To copy an existing checkout from Windows storage, first stop tools that write to
it, then use an unused destination name:

```bash
test ! -e ~/code/cdc/ocio-wsl && \
  rsync -a /mnt/c/Users/<username>/code/cdc/ocio-wsl/ ~/code/cdc/ocio-wsl/
cd ~/code/cdc/ocio-wsl
git status
```

The copy preserves Git history, local changes, and untracked files. Keep the
original until you have verified the Linux checkout. For other projects, recreate
dependencies and virtual environments in the new location when they contain
absolute paths or platform-specific binaries. Reopen your editor using its WSL
connection to the Linux checkout.

The optional `~/shared` link points to `%USERPROFILE%\wsl-shared` on Windows.
Use it for file transfers; keep repositories and build output under `~/code/cdc`.

## Rootless Podman

Run Podman as your normal user; `sudo` is not required:

```bash
podman info --format '{{.Host.Security.Rootless}}'
podman run --rm quay.io/podman/hello
```

The first command should print `true`. If it does not, repair the current user and retry:

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

The command requests a passphrase and uses ED25519 with OpenSSH’s encrypted private-key format and a high key-derivation work factor. The private key stays in `~/.ssh/github_ed25519`; only the `.pub` file should be added to GitHub.

For a dedicated GitHub SSH configuration, add this to `~/.ssh/config`:

```sshconfig
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/github_ed25519
    IdentitiesOnly yes
```

Protect the configuration with `chmod 600 ~/.ssh/config`. If you use multiple GitHub accounts, give each account a separate `Host` alias and key instead of reusing this entry. Newer OpenSSH versions may also support post-quantum key exchange; inspect support with `ssh -Q kex | grep -E '(mlkem|sntrup)'` before configuring it.

## If the default user is still root after first login

Check `sudo systemctl status run-once.service` and
`sudo journalctl -u run-once.service`. Setup allows six start attempts until the
distro restarts or the service is reset. Each attempt has a 30-second startup
timeout and a 5-second shutdown timeout; persistent failures remain visible.
Windows username and profile detection have separate 5-second timeouts, followed
by forced termination after another 2 seconds if needed. Waiting for another
account setup process is limited to 35 seconds.

A tool setup failure does not block recording the default user or attempting the
remaining setup steps. Interrupted password initialization is tracked under
`/var/lib/cdc-wsl` so it can resume for the account created by setup. Passwords on
established accounts, including passwords set after an interrupted attempt, are
preserved.

If you used `wsl --import` and Windows username detection keeps failing, run this
as root, replacing `myuser` with your preferred UNIX username:

```bash
/opt/scripts/create-default-user.sh myuser
systemctl reset-failed run-once.service
systemctl restart run-once.service
```

Once the account exists, rerunning the helper finishes its setup. OOBE reports
setup failures for an existing account without prompting for another username.

To force a restart immediately: `wsl --terminate <distroName>` from a Windows terminal, then log back in.

To revert to root as default, change the `default` entry in `/etc/wsl.conf` to `root` and terminate/restart the distro.

## If DNS is not resolving

New images use `generateResolvConf = true` in `/etc/wsl.conf`. WSL owns the resolver
file; the startup service does not snapshot DNS server addresses from Windows.
See [Microsoft's WSL configuration reference](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)
for DNS generation and tunneling settings.

For an existing installation with the old configuration:

1. Set `generateResolvConf = true` under `[network]` in `/etc/wsl.conf`.
2. If you previously made `/etc/resolv.conf` immutable, remove that attribute with
   `sudo chattr -i /etc/resolv.conf`.
3. Terminate the distro from Windows with `wsl --terminate <distroName>`, then
   launch it again so WSL regenerates the resolver file.

Check `cat /etc/resolv.conf` and `getent hosts github.com`. If resolution still
fails, check Windows networking and VPN connectivity. Avoid manually overwriting
the generated resolver file; those edits do not persist when WSL regenerates it.
