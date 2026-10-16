#!/usr/bin/env bash
# Create the standard CDC workspace and an optional bridge to the Windows profile.

set -eu

USERNAME="${1:?username is required}"
WINDOWS_HOME="${2:-}"
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
USER_GROUP="$(id -gn "$USERNAME")"

if [ -z "$USER_HOME" ]; then
  echo "Could not determine the home directory for '$USERNAME'" >&2
  exit 1
fi

# Repositories stay on WSL's native Linux filesystem for good I/O performance.
install -d -m 0755 -o "$USERNAME" -g "$USER_GROUP" \
  "$USER_HOME/code" "$USER_HOME/code/cdc"

# A caller may supply a path (which also makes this script easy to test). When
# omitted, translate the current Windows user's profile path into a WSL path.
if [ -z "$WINDOWS_HOME" ]; then
  CMD_EXE=''
  for candidate in \
    /mnt/c/Windows/System32/cmd.exe \
    /mnt/c/windows/system32/cmd.exe; do
    if [ -x "$candidate" ]; then
      CMD_EXE="$candidate"
      break
    fi
  done

  if [ -n "$CMD_EXE" ] && command -v wslpath >/dev/null 2>&1; then
    WINDOWS_HOME_RAW=$(timeout --kill-after=2s 5s "$CMD_EXE" /d /c 'echo %USERPROFILE%' 9>&- 2>/dev/null | tr -d '\r') || WINDOWS_HOME_RAW=''
    if [ -n "$WINDOWS_HOME_RAW" ] && [ "$WINDOWS_HOME_RAW" != '%USERPROFILE%' ]; then
      WINDOWS_HOME=$(wslpath -u "$WINDOWS_HOME_RAW" 2>/dev/null) || WINDOWS_HOME=''
    fi
  fi
fi

SHARED_LINK="$USER_HOME/shared"
if [ -n "$WINDOWS_HOME" ] && [ -d "$WINDOWS_HOME" ]; then
  WINDOWS_SHARED="$WINDOWS_HOME/wsl-shared"
  if install -d -m 0755 -o "$USERNAME" -g "$USER_GROUP" "$WINDOWS_SHARED"; then
    # A previous boot may have run before Windows interop was ready. Only an
    # empty local directory can be upgraded; existing files and links stay put.
    if [ -d "$SHARED_LINK" ] && [ ! -L "$SHARED_LINK" ]; then
      rmdir -- "$SHARED_LINK" 2>/dev/null || true
    fi
    if [ ! -e "$SHARED_LINK" ] && [ ! -L "$SHARED_LINK" ]; then
      # OOBE and the startup service can briefly overlap on first boot.
      if ln -sT "$WINDOWS_SHARED" "$SHARED_LINK" 2>/dev/null; then
        chown -h "$USERNAME:$USER_GROUP" "$SHARED_LINK"
      fi
    fi
  fi
fi

# Keep the name useful even when Windows interop is unavailable (for example,
# while testing the image as a container).
if [ ! -e "$SHARED_LINK" ] && [ ! -L "$SHARED_LINK" ]; then
  install -d -m 0755 -o "$USERNAME" -g "$USER_GROUP" "$SHARED_LINK"
fi

echo "Workspace ready at $USER_HOME/code/cdc"
if [ -L "$SHARED_LINK" ]; then
  echo "Windows transfer folder available at $SHARED_LINK -> $(readlink "$SHARED_LINK")"
else
  echo "Local shared directory ready at $SHARED_LINK; rerun setup to retry Windows linking."
fi
