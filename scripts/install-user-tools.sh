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
    /etc/skel/.config/mise/config.toml "$USER_CONFIG_FILE"
fi

echo "mise is ready for $USERNAME. Run 'mise install' after logging in to install tools."
