#!/bin/bash
# WSL out-of-box experience: runs once on first interactive shell launch.
# Creates a non-root user matching the Windows login (with sudo access).
set -ue

DEFAULT_UID='1000'

if getent passwd "$DEFAULT_UID" > /dev/null 2>&1; then
    echo 'User account already exists, skipping creation'
    exit 0
fi

# Try to auto-detect Windows username; fall back to interactive prompt
RAWUSER=$(/mnt/c/windows/system32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r') || RAWUSER=""
WINDOWS_USER=$(echo "$RAWUSER" | awk -F'/' '{print $NF}' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')

# Determine the appropriate sudo group (wheel on Fedora, sudo on Debian/Ubuntu)
SUDO_GROUP='sudo'
if getent group wheel > /dev/null 2>&1 && ! getent group sudo > /dev/null 2>&1; then
    SUDO_GROUP='wheel'
fi

# Build list of groups that actually exist on this distro
GROUPS_TO_ADD="$SUDO_GROUP"
for group in adm cdrom dip plugdev; do
    if getent group "$group" > /dev/null 2>&1; then
        GROUPS_TO_ADD="$GROUPS_TO_ADD,$group"
    fi
done

create_user() {
    local username="$1"
    /usr/sbin/useradd --uid "$DEFAULT_UID" --create-home --shell /bin/bash "$username"
    /usr/sbin/usermod "$username" -aG "$GROUPS_TO_ADD"
    passwd -d "$username"
    # shellcheck disable=SC2016
  if ! grep -qF 'eval "$(mise activate bash)"' "/home/$username/.bashrc"; then
    echo 'eval "$(mise activate bash)"' >> "/home/$username/.bashrc"
  fi
}

if [ -n "$WINDOWS_USER" ]; then
    echo "Creating user '$WINDOWS_USER' (from Windows login)..."
    create_user "$WINDOWS_USER"
else
    echo 'Please create a default UNIX user account.'
    echo 'For more information visit: https://aka.ms/wslusers'
    while true; do
        read -rp 'Enter new UNIX username: ' username
        if create_user "$username"; then
            break
        fi
    done
fi
