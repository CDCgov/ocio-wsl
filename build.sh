#!/usr/bin/env bash

set -eu

if command -v podman > /dev/null 2>&1 ; then
  echo "podman found"
  podman -v
else
  echo "podman not found! Please install podman and run again!"
  exit
fi

if command -v awk > /dev/null 2>&1 ; then
  echo "awk found"
else
  echo "awk not found! Please install awk and run again!"
  exit
fi

TAR_DIR="$PWD/images"
mkdir -p "$TAR_DIR"
IMAGE_NAME="ubuntu-24.04-cdc"

# Build, run, and save the image as a docker image in a tar file
# so it can be used later
echo "Building image $IMAGE_NAME"
podman build . -t "$IMAGE_NAME"

echo "Running image $IMAGE_NAME"
podman run -t "$IMAGE_NAME" sh -c echo
containerID=$(podman container ls -a | grep -i "$IMAGE_NAME" | awk '{print $1}')
TAR_NAME=$(echo "$IMAGE_NAME" | tr '/' '_').tar

echo "Exporting image $containerID > $TAR_DIR/$TAR_NAME"
podman export "$containerID" > "$TAR_DIR"/"$TAR_NAME"

# Remove the image from podman container storage to avoid piling up of containers
containerIDs=($(podman container ls -a | grep -i "$IMAGE_NAME" | awk '{print $1}'))
echo "Removing containers with image: $IMAGE_NAME"
for containerID in "${containerIDs[@]}"
do
  echo "Removing container ID: $containerID"
  podman rm "$containerID"
done

