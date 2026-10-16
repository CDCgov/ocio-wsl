#!/usr/bin/env bash
# Finish user setup on every WSL boot, including imports that do not run OOBE.
# DNS is managed by WSL through generateResolvConf in /etc/wsl.conf.
# run-once.service retries failures briefly; persistent failures remain visible
# through systemctl status run-once.service and journalctl -u run-once.service.
set -u

if /opt/scripts/create-default-user.sh; then
  exit 0
else
  status=$?
fi

if [ "$status" -eq 3 ]; then
  echo 'Windows username unavailable; startup setup will retry.' >&2
  echo 'For an imported distro, run /opt/scripts/create-default-user.sh <username> as root if detection keeps failing.' >&2
fi
exit "$status"
