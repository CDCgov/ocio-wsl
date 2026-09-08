# First-Time Setup

This serves just a simple knowledge base on how we automated the initial setup sequence, it's not meant to be followed unless something wrong happened with the image.

When you first launch the distro, a startup script (`run-once.service`) runs automatically and handles:

- **User creation** - creates a non-root account matching your Windows username and grants it `sudo` access
- **DNS configuration** - reads your Windows DNS resolver IPs and writes them to `/etc/resolv.conf`

You do not need to do anything manually for these steps.

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

Log out, wait one minute, then log back in. WSL needs time to restart the distro with the new default user set in `/etc/wsl.conf`.

To force a restart immediately: `wsl --terminate <distroName>` from a Windows terminal, then log back in.

To revert to root as default, change the `default` entry in `/etc/wsl.conf` to `root` and terminate/restart the distro.

## If DNS is not resolving

The run-once script writes nameservers from your Windows DNS configuration. If it did not run or the file is empty:

1. Empty `/etc/resolv.conf`: `sudo truncate -s 0 /etc/resolv.conf`
2. Terminate the distro: `wsl --terminate <distroName>`
3. Log back in and the script will reconfigure DNS on startup

If you need to configure DNS manually:

```bash
sudo tee /etc/resolv.conf <<'EOF'
nameserver <your-gateway-ip>
EOF
sudo chmod 644 /etc/resolv.conf
```
