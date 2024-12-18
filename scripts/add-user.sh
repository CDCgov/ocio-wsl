#!/usr/bin/env bash

set -eu

# Get the Windows username and extract only the part after the domain (if present)
RAWUSER=$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')
NEWUSER=$(echo "$RAWUSER" | awk -F'/' '{print $NF}')

# Check if the user already exists
if getent passwd "$NEWUSER" > /dev/null; then
  echo -e "The user '$NEWUSER' already exists - skipping creation."
else
  echo -e "The user '$NEWUSER' does not exist. Creating user with sudo permissions in Ubuntu..."
  sudo useradd -ms /bin/bash "$NEWUSER"
  sudo usermod -aG sudo "$NEWUSER"
  sudo passwd -d "$NEWUSER" # Default empty password for the user

  echo -e "User '$NEWUSER' created successfully!"
fi

# Set the user as the default for WSL
if ! grep -q "default=${NEWUSER}" /etc/wsl.conf; then
  echo -e "[user]\ndefault=${NEWUSER}" | sudo tee -a /etc/wsl.conf > /dev/null
  echo "Default user set to '${NEWUSER}' in WSL configuration."
else
  echo "Default user '${NEWUSER}' is already set in WSL configuration."
fi
