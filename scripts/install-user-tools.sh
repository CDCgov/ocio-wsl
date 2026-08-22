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

# Azure CLI installs through mise's uv-backed pipx backend. Its environment
# intentionally omits pip, but `az extension add` uses pip to install wheels.
# Bootstrap pip inside Azure CLI's own environment without relying on the
# user's separately managed Python installation.
# shellcheck disable=SC2016
runuser -u "$USERNAME" -- env \
  HOME="$USER_HOME" \
  MISE_SYSTEM_CONFIG_DIR=/etc/mise \
  /bin/bash -c '
    azure_root=$(mise where azure-cli 2>/dev/null || true)
    azure_python="$azure_root/azure-cli/bin/python"
    if [ -x "$azure_python" ]; then
      "$azure_python" -m ensurepip --upgrade >/dev/null
    fi
  '
