#!/usr/bin/env bash

set -eu

# Default paths
TOOL_VERSIONS_PATH=${1:-config/config.toml}
OUTPUT_FILE=${2:-config.toml.latest}

# Ensure required tools are installed
if ! command -v yq &>/dev/null; then
  echo "error: yq is required but not installed. Install it from https://github.com/mikefarah/yq"
  exit 1
fi

if ! command -v mise &>/dev/null; then
  echo "error: mise is required but not installed. Install it from https://mise.jdx.dev"
  exit 1
fi

# Check if the input TOML file exists
if [[ ! -f $TOOL_VERSIONS_PATH ]]; then
  echo "error: File not found: $TOOL_VERSIONS_PATH"
  exit 1
fi

# Start the output file
echo "[tools]" > "$OUTPUT_FILE"

# Process top-level tools
yq -r '.tools | to_entries | .[] | select(.value | type != "object") | "\(.key) \(.value)"' "$TOOL_VERSIONS_PATH" | while read -r package version; do
  latest_version=$(mise latest "$package" 2>/dev/null || echo "$version")
  echo "  $package = \"$latest_version\"" >> "$OUTPUT_FILE"
done

# Process nested tool categories like [tools.java]
yq -r '.tools | to_entries | .[] | select(.value | type == "object") | .key' "$TOOL_VERSIONS_PATH" | while read -r category; do
  echo "" >> "$OUTPUT_FILE"
  echo "[tools.$category]" >> "$OUTPUT_FILE"

  yq -r ".tools[\"$category\"] | to_entries | .[] | \"\(.key) \(.value)\"" "$TOOL_VERSIONS_PATH" | while read -r subpackage subversion; do
    latest_version=$(mise latest "$subpackage" 2>/dev/null || echo "$subversion")
    echo "  $subpackage = \"$latest_version\"" >> "$OUTPUT_FILE"
  done
done

echo "Updated config.toml file created as $OUTPUT_FILE"