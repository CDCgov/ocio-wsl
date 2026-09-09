#!/usr/bin/env bash
# Prepare a newly-created WSL user for rootless Podman.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <username>" >&2
  exit 2
fi

USERNAME="$1"

if [ "$(id -u)" -ne 0 ]; then
  echo 'Rootless Podman setup must be run as root.' >&2
  exit 1
fi

if ! id "$USERNAME" > /dev/null 2>&1; then
  echo "Cannot configure rootless Podman: user '$USERNAME' does not exist." >&2
  exit 1
fi

ensure_subordinate_ids() {
  local map_file="$1"
  local range_type="$2"
  local minimum maximum count start end option

  if awk -F: -v username="$USERNAME" '$1 == username { found = 1 } END { exit !found }' "$map_file"; then
    return
  fi

  minimum=$(awk -v key="SUB_${range_type}_MIN" '$1 == key { print $2; exit }' /etc/login.defs)
  maximum=$(awk -v key="SUB_${range_type}_MAX" '$1 == key { print $2; exit }' /etc/login.defs)
  count=$(awk -v key="SUB_${range_type}_COUNT" '$1 == key { print $2; exit }' /etc/login.defs)
  minimum=${minimum:-100000}
  maximum=${maximum:-600100000}
  count=${count:-65536}

  # Allocate after the highest existing range. Fresh accounts normally already
  # have a range; this repairs accounts imported or created without one.
  start=$(awk -F: -v minimum="$minimum" '
    BEGIN { next_id = minimum }
    NF >= 3 && ($2 + $3) > next_id { next_id = $2 + $3 }
    END { print next_id }
  ' "$map_file")
  end=$((start + count - 1))
  if [ "$end" -gt "$maximum" ]; then
    echo "No subordinate ${range_type,,} range is available for '$USERNAME'." >&2
    exit 1
  fi

  if [ "$range_type" = 'UID' ]; then
    option='--add-subuids'
  else
    option='--add-subgids'
  fi
  usermod "$option" "$start-$end" "$USERNAME"
}

ensure_mapping_helper() {
  local command_name="$1"
  local capability="$2"
  local helper_path

  helper_path=$(command -v "$command_name")

  # Ubuntu supplies these helpers setuid-root. Fedora uses file capabilities,
  # which can be lost when an OCI image is exported and imported into WSL.
  if [ -u "$helper_path" ] || getcap "$helper_path" | grep -q "$capability"; then
    return
  fi

  setcap "${capability}=ep" "$helper_path"
  getcap "$helper_path" | grep -q "$capability"
}

ensure_subordinate_ids /etc/subuid UID
ensure_subordinate_ids /etc/subgid GID
ensure_mapping_helper newuidmap cap_setuid
ensure_mapping_helper newgidmap cap_setgid

echo "Rootless Podman is configured for '$USERNAME'."
