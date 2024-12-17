#!/usr/bin/env bash

set -eu

# Default path to .tool-versions file if not set
TOOL_VERSIONS_PATH=${1:-config/.tool-versions}
OUTPUT_FILE=${2:-.tool-versions.latest}

get_latest_version() {
  local package=$1
  local latest_version
  latest_version=$(asdf latest "$package" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "error: $latest_version"
  else
    echo "$latest_version"
  fi
}

if [[ ! -f $TOOL_VERSIONS_PATH ]]; then
  echo "File not found: $TOOL_VERSIONS_PATH"
  exit 1
fi

# Read the .tool-versions file and update with latest versions
while read -r line; do
  package=$(echo "$line" | awk '{print $1}')
  latest_version=$(get_latest_version "$package")
  echo "$package $latest_version"
done < "$TOOL_VERSIONS_PATH" > "$OUTPUT_FILE"

echo "Updated .tool-versions file created as .tool-versions.latest"