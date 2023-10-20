#!/usr/bin/env bash

set -eu

file_path="VERSION"

is_valid_version() {
  [[ $1 =~ ^[0-9]+\.[0-9]+$ ]]
}

if [ -f "$file_path" ]; then
  VERSION="$(cat "$(pwd)/$file_path")"
  if is_valid_version "$VERSION"; then
    echo "VERSION: $VERSION"
  else
    echo "Error: Invalid version format in file: $file_path"
  fi
else
  echo "File not found: $file_path"
fi

IMAGE_NAME="ubuntu-22.04-cdc"
IMAGE_VERSION="$VERSION"

# Use awk to extract container IDs into an array
containerIDs=($(podman container ls -a | grep -i "$IMAGE_NAME:$IMAGE_VERSION" | awk '{print $1}'))

# Remove the image from podman container storage to avoid piling up of containers
echo "Removing containers with image: $IMAGE_NAME:$IMAGE_VERSION"
for containerID in "${containerIDs[@]}"
do
  echo "Removing container ID: $containerID"
  podman rm "$containerID"
done
