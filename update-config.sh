#!/usr/bin/env bash

set -euo pipefail

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

# This file is not in mise's normal config discovery path. Pass its release-age
# policy explicitly so updates retain the same supply-chain delay as installs.
minimum_release_age=$(yq -r '.settings.minimum_release_age // "14d"' "$TOOL_VERSIONS_PATH")

latest_version_for() {
  local package=$1 current=$2 latest
  if latest=$(mise latest --minimum-release-age "$minimum_release_age" "$package") && [[ -n $latest ]]; then
    printf '%s\n' "$latest"
  else
    echo "warning: Could not resolve $package; keeping $current" >&2
    printf '%s\n' "$current"
  fi
}

# Start the output file
echo "[tools]" > "$OUTPUT_FILE"

# Process tools in their original order. Tools with options, e.g.
# "tool" = { version = "1.0", depends = ["python"] }, are written back as
# inline tables with only the version bumped.
yq -r '.tools | keys | .[]' "$TOOL_VERSIONS_PATH" | while read -r package; do
  if [[ $(yq -r ".tools[\"$package\"] | tag" "$TOOL_VERSIONS_PATH") == "!!map" ]]; then
    version=$(yq -r ".tools[\"$package\"].version" "$TOOL_VERSIONS_PATH")
    latest_version=$(latest_version_for "$package" "$version")
    # Strings and arrays of strings serialize identically in JSON and TOML
    options=$(yq -r ".tools[\"$package\"] | del(.version) | to_entries | .[] | \", \" + .key + \" = \" + (.value | @json)" "$TOOL_VERSIONS_PATH" | tr -d '\n')
    echo "\"$package\" = { version = \"$latest_version\"$options }" >> "$OUTPUT_FILE"
  else
    version=$(yq -r ".tools[\"$package\"]" "$TOOL_VERSIONS_PATH")
    latest_version=$(latest_version_for "$package" "$version")
    echo "\"$package\" = \"$latest_version\"" >> "$OUTPUT_FILE"
  fi
done

# Carry over every non-tools table (e.g. [settings]) unchanged
awk '/^\[/ { keep = ($0 !~ /^\[tools[].]/); if (keep) print "" } keep' "$TOOL_VERSIONS_PATH" >> "$OUTPUT_FILE"

echo "Updated config.toml file created as $OUTPUT_FILE"
# Review the output before replacing the original, since comments are not carried over
echo "Review it, then apply with: mv $OUTPUT_FILE $TOOL_VERSIONS_PATH"
