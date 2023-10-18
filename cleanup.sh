#!/usr/bin/env bash

set -eu

IMAGE_NAME="ubuntu-22.04-cdc"
IMAGE_VERSION="1.2"

# Use awk to extract container IDs into an array
containerIDs=($(podman container ls -a | grep -i "$IMAGE_NAME:$IMAGE_VERSION" | awk '{print $1}'))

# Remove the image from podman container storage to avoid piling up of containers
echo "Removing containers with image: $IMAGE_NAME:$IMAGE_VERSION"
for containerID in "${containerIDs[@]}"
do
  echo "Removing container ID: $containerID"
  podman rm "$containerID"
done
