#!/usr/bin/env bash
# Create (or finish setting up) the default WSL user at UID 1000.
#
# Called by both /etc/oobe.sh (wsl --install) and run-once.sh (every boot,
# which also covers wsl --import where OOBE does not run). Both can fire on
# the same first boot, so the work is serialized with a lock and UID 1000 is
# the single source of truth: whichever caller runs second reuses that account.
#
# Usage: create-default-user.sh [username]
#   Without a username, the Windows login name is used.
# Exit codes: 0 success, 1 failure, 3 no username could be determined.
set -euo pipefail

DEFAULT_UID='1000'
LOCK_FILE='/run/lock/cdc-default-user.lock'
STATE_DIR='/var/lib/cdc-wsl'
PENDING_PASSWORD_FILE="$STATE_DIR/pending-user-password"

if [ "$(id -u)" -ne 0 ]; then
  echo 'Default user setup must be run as root.' >&2
  exit 1
fi

# Lowercase and keep only characters useradd accepts on every distro
sanitize_username() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g'
}

windows_username() {
  local raw
  raw=$(timeout --kill-after=2s 5s /mnt/c/windows/system32/cmd.exe /d /c 'echo %USERNAME%' 9>&- 2>/dev/null | tr -d '\r') || return 0
  [ "$raw" != '%USERNAME%' ] || return 0
  # Drop a DOMAIN\ prefix if one is ever present
  sanitize_username "${raw##*\\}"
}

mkdir -p "$(dirname "$LOCK_FILE")"
exec 9> "$LOCK_FILE"
if ! flock -w 35 9; then
  echo 'Timed out waiting for another default-user setup process.' >&2
  exit 1
fi

if getent passwd "$DEFAULT_UID" > /dev/null 2>&1; then
  USERNAME=$(getent passwd "$DEFAULT_UID" | cut -d: -f1)
  echo "User account '$USERNAME' already exists, skipping creation"
else
  if [ "$#" -gt 0 ]; then
    USERNAME=$(sanitize_username "$1")
  else
    USERNAME=$(windows_username)
  fi
  if [ -z "$USERNAME" ]; then
    echo 'Could not determine a username for the default account.' >&2
    exit 3
  fi

  # wheel on Fedora, sudo on Debian/Ubuntu, plus the usual desktop groups
  SUDO_GROUP='sudo'
  if getent group wheel > /dev/null 2>&1 && ! getent group sudo > /dev/null 2>&1; then
    SUDO_GROUP='wheel'
  fi
  GROUPS_TO_ADD="$SUDO_GROUP"
  for group in adm cdrom dip plugdev; do
    if getent group "$group" > /dev/null 2>&1; then
      GROUPS_TO_ADD="$GROUPS_TO_ADD,$group"
    fi
  done

  echo "Creating user '$USERNAME'..."
  # Persist intent before useradd: it can create the account before a later
  # step fails or the service is stopped. Only our own pending account may
  # receive the initial empty password on a retry.
  install -d -m 0700 "$STATE_DIR"
  (umask 077; printf '%s\n' "$USERNAME" > "$PENDING_PASSWORD_FILE")
  /usr/sbin/useradd --uid "$DEFAULT_UID" --create-home --shell /bin/bash \
    --groups "$GROUPS_TO_ADD" "$USERNAME"
fi

if [ -f "$PENDING_PASSWORD_FILE" ]; then
  if [ "$(cat "$PENDING_PASSWORD_FILE")" != "$USERNAME" ]; then
    echo 'Pending password setup belongs to a different account; manual repair is required.' >&2
    exit 1
  fi
  # useradd uses a bare lock marker for a new account. Preserve any password
  # set since the interrupted attempt, including a locked password hash.
  password_hash=$(getent shadow "$USERNAME" | cut -d: -f2)
  case "$password_hash" in
    '!'|'!!') passwd -d "$USERNAME" ;;
  esac
  unset password_hash
  rm -- "$PENDING_PASSWORD_FILE"
fi

# wsl-distribution.conf sets defaultUid for wsl --install; wsl --import only
# honours /etc/wsl.conf, so record the default user there too.
if ! grep -qx "default=${USERNAME}" /etc/wsl.conf; then
  printf '\n[user]\ndefault=%s\n' "$USERNAME" >> /etc/wsl.conf
  echo "Default user set to '$USERNAME' in /etc/wsl.conf"
fi

# Each step must get a chance to finish even if another tool needs repair.
# Keep a failing status so the startup service retries unfinished setup.
status=0
/opt/scripts/install-user-tools.sh "$USERNAME" || status=1
/opt/scripts/setup-user-workspace.sh "$USERNAME" || status=1
/opt/scripts/configure-rootless-podman.sh "$USERNAME" || status=1
exit "$status"
