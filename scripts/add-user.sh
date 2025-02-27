#!/usr/bin/env bash

set -eu

# use the Windows username and extract only the part after the domain (if present)
# which is normally the way we login into Windows
RAWUSER=$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')
NEWUSER=$(echo "$RAWUSER" | awk -F'/' '{print $NF}')

# check and verify if the user already exists
if getent passwd "$NEWUSER" > /dev/null; then
  echo -e "The user '$NEWUSER' already exists - skipping creation."
else
  echo -e "The user '$NEWUSER' does not exist. Creating user with sudo permissions in Ubuntu..."
  useradd -ms /bin/bash "$NEWUSER"
  usermod -aG sudo "$NEWUSER"
  passwd -d "$NEWUSER" # Default empty password for the user

  echo -e "User '$NEWUSER' created successfully!"
fi

# Set the user as the default for WSL
if ! grep -q "default=${NEWUSER}" /etc/wsl.conf; then
  echo -e "\n\n[user]\ndefault=${NEWUSER}" | tee -a /etc/wsl.conf > /dev/null
  echo "Default user set to '${NEWUSER}' in WSL configuration."
else
  echo "Default user '${NEWUSER}' is already set in WSL configuration."
fi
