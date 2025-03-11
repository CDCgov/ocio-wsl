#!/usr/bin/env bash

set -eu

IMAGE_NAME="ubuntu-24.04-cdc"

# Use awk to extract container IDs into an array
containerIDs=("$(podman container ls -a | grep -i "$IMAGE_NAME" | awk '{print $1}')")

# Remove the image from podman container storage to avoid piling up of containers
echo "Removing containers with image: $IMAGE_NAME"
for containerID in "${containerIDs[@]}"
do
  echo "Removing container ID: $containerID"
  podman rm "$containerID"
done

podman stop ubuntu-24.04-cdc-test && podman rm ubuntu-24.04-cdc-test