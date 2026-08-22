#!/usr/bin/env bash

set -eu

USERNAME="${1:?username is required}"
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
USER_GROUP="$(id -gn "$USERNAME")"
USER_CONFIG_DIR="$USER_HOME/.config/mise"
USER_CONFIG_FILE="$USER_CONFIG_DIR/config.toml"

install -d -m 0755 -o "$USERNAME" -g "$USER_GROUP" "$USER_CONFIG_DIR"

if [ ! -f "$USER_CONFIG_FILE" ]; then
  install -m 0644 -o "$USERNAME" -g "$USER_GROUP" \
    /etc/mise/config.toml "$USER_CONFIG_FILE"
fi

echo "Installing mise tools for $USERNAME..."
if ! runuser -u "$USERNAME" -- env \
    HOME="$USER_HOME" \
    MISE_SYSTEM_CONFIG_DIR=/etc/mise \
    /usr/bin/mise install; then
  echo "WARNING: mise tool installation did not complete. Run 'mise install' as $USERNAME to retry."
fi

# Keep Azure CLI extensions independent of the user's separately managed
# Python installation. The custom asdf plugin normally creates a private venv
# with pip; the first path below supports the native backend for upgrades from
# older images that used it.
# shellcheck disable=SC2016
runuser -u "$USERNAME" -- env \
  HOME="$USER_HOME" \
  MISE_SYSTEM_CONFIG_DIR=/etc/mise \
  /bin/bash -c '
    azure_root=$(mise where azure-cli 2>/dev/null || true)
    for azure_python in \
      "$azure_root/bin/venv/bin/python3" \
      "$azure_root/azure-cli/bin/python"; do
      if [ -x "$azure_python" ]; then
        "$azure_python" -m ensurepip --upgrade >/dev/null
        break
      fi
    done
  '
