# First-Time Setup

This serves just a simple knowledge base on how we automated the initial setup sequence, it's not meant to be followed unless something wrong happened with the image.

When you first launch the distro, a startup script (`run-once.service`) runs automatically and handles:

- **User creation** - creates a non-root account matching your Windows username and grants it `sudo` access
- **DNS configuration** - reads your Windows DNS resolver IPs and writes them to `/etc/resolv.conf`

You do not need to do anything manually for these steps.

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
