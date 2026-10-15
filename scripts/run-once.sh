#!/usr/bin/env bash
# This script is for any action to be run once on startup and is called by a custom systemd unit: run-once.service
#
# Currently, it does the following if not already configured:
# - Configures DNS resolution matching the Windows configuration using /etc/resolv.conf
# - Creates and sets the default login user to a non-root user matching the windows login username and with sudo access
#
# DNS runs first and the steps are independent, so a failure in one does not
# skip the other. The service is marked failed if either step fails.
#
# To get the status or check for errors: sudo systemctl status run-once.service
# To disable the service: sudo systemctl disable run-once.service
# To reenable the service: sudo systemctl enable run-once.service

set -u

DNSFILE=/etc/resolv.conf
POWERSHELL=/mnt/c/windows/system32/windowspowershell/v1.0/powershell.exe

# Configure DNS based on Windows configuration if not already configured
configure_dns() {
  local dnslist attempt

  if [ -s "$DNSFILE" ]; then
    echo "Using existing DNS configuration in $DNSFILE"
    return 0
  fi

  echo "Configuring DNS $DNSFILE with resolver IPs from Windows"
  # Windows interop can lag behind early boot, so retry briefly
  for attempt in 1 2 3 4 5; do
    dnslist=$("$POWERSHELL" -NoProfile -Command \
      "Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses" \
      2>/dev/null | tr -d '\r' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | awk '!seen[$0]++') || true
    [ -n "$dnslist" ] && break
    echo "No IPv4 resolvers found from Windows (attempt $attempt/5)"
    sleep 2
  done

  if [ -z "$dnslist" ]; then
    echo "Could not read DNS resolvers from Windows; leaving $DNSFILE unchanged" >&2
    return 1
  fi

  echo "Detected nameservers: $dnslist"
  while read -r ip; do
    echo "nameserver $ip"
  done <<< "$dnslist" > "$DNSFILE"
  chmod 644 "$DNSFILE"
  echo "DNS configuration written to $DNSFILE:"
  cat "$DNSFILE"
}

status=0
configure_dns || status=1

# Exit code 3 means no Windows username was available; OOBE will prompt for one
user_status=0
/opt/scripts/create-default-user.sh || user_status=$?
if [ "$user_status" -ne 0 ] && [ "$user_status" -ne 3 ]; then
  status=1
fi

exit "$status"
