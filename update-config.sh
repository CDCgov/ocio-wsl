#!/usr/bin/env bash

set -eu

# Default path to config.toml file if not set
TOOL_VERSIONS_PATH=${1:-config/config.toml}
OUTPUT_FILE=${2:-config.toml.latest}

get_latest_version() {
  local package=$1
  local latest_version
  latest_version=$(mise latest "$package" 2>&1)
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

# Read the config.toml file and update with latest versions
echo "[tool]" > "$OUTPUT_FILE"

first_line_skipped=false
while read -r line; do
  if [ "$first_line_skipped" = false ]; then
    first_line_skipped=true
    continue
  fi
  package=$(echo "$line" | awk '{print $1}' | tr -d '"')
  version=$(echo "$line" | awk -F'=' '{print $2}' | tr -d ' "')
  if [ "$version" = "latest" ]; then
    latest_version="latest"
  else
    latest_version=$(get_latest_version "$package")
  fi
  echo "$package = \"$latest_version\"" >> "$OUTPUT_FILE"
done < "$TOOL_VERSIONS_PATH"

echo "Updated config.toml file created as config.toml.latest"