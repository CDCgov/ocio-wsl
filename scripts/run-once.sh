#!/usr/bin/env bash
# This script is for any action to be run once on startup and is called by a custom systemd unit: run-once.service
#
# Currently, it does the following if not already configured:
# - Creates and sets the default login user to a non-root user matching the windows login username and with sudo access
# - Configures DNS resolution matching the Windows configuration using /etc/resolv.conf
#
# To get the status or check for errors: sudo systemctl status run-once.service
# To disable the service: sudo systemctl disable run-once.service
# To reenable the service: sudo systemctl enable run-once.service

set -eu

# use the Windows username and extract only the part after the domain (if present)
# which is normally the way we login into Windows
RAWUSER=$(/mnt/c/windows/system32/cmd.exe /c "echo %USERNAME%" | tr -d '\r')
NEWUSER=$(echo "$RAWUSER" | awk -F'/' '{print $NF}')

# check and verify if the user already exists, create if not
if getent passwd "$NEWUSER" > /dev/null; then
  echo -e "The user '$NEWUSER' already exists - skipping creation."
else
  echo -e "The user '$NEWUSER' does not exist. Creating user with sudo permissions in Ubuntu..."
  useradd -ms /bin/bash "$NEWUSER"
  usermod -aG sudo "$NEWUSER"
  passwd -d "$NEWUSER" # Default empty password for the user

  echo -e "User '$NEWUSER' created successfully!"
fi

# Set the user as the default for WSL for ease of access
if ! grep -q "default=${NEWUSER}" /etc/wsl.conf; then
  echo -e "\n\n[user]\ndefault=${NEWUSER}" | tee -a /etc/wsl.conf > /dev/null
  echo "Default user set to '${NEWUSER}' in WSL configuration."
else
  echo "Default user '${NEWUSER}' is already set in WSL configuration."
fi

# Configure DNS based on Windows configuration if not already configured
DNSFILE=/etc/resolv.conf
if [ -s "$DNSFILE" ]; then
  echo "Using existing DNS configuration in $DNSFILE"
else
  echo "Configuring DNS $DNSFILE with resolver IPs from Windows"
  DNSLIST=$(/mnt/c/windows/system32/windowspowershell/v1.0/powershell.exe -command "Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses" | tr -d '\r')
  for ip in $(echo $DNSLIST); do
    echo "nameserver $ip" >> $DNSFILE
  done
fi

# Add mise to the user's bashrc for the user's environment for easy access
# shellcheck disable=SC2016
echo 'eval "$(mise activate bash)"' >> "/home/$NEWUSER/.bashrc"
