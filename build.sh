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
IMAGE_NAME="ubuntu-22.04-cdc"
IMAGE_VERSION="1.0"

# Build, run, and save the image as a docker image in a tar file
# so it can be used later
echo "Building image $IMAGE_NAME:$IMAGE_VERSION"
podman build . -t "$IMAGE_NAME:$IMAGE_VERSION"

echo "Running image $IMAGE_NAME:$IMAGE_VERSION"
podman run -t "$IMAGE_NAME:$IMAGE_VERSION" sh -c echo
containerID=$(podman container ls -a | grep -i "$IMAGE_NAME:$IMAGE_VERSION" | awk '{print $1}')
TAR_NAME=$(echo "$IMAGE_NAME:$IMAGE_VERSION" | tr '/' '_')-$(date -u +%Y%m%d%I%M).tar

echo "Exporting image $containerID > $TAR_DIR/$TAR_NAME"
podman export "$containerID" > "$TAR_DIR"/"$TAR_NAME"

# Remove the image from podman container storage to avoid piling up of containers
containerIDs=($(podman container ls -a | grep -i "$IMAGE_NAME:$IMAGE_VERSION" | awk '{print $1}'))
echo "Removing containers with image: $IMAGE_NAME:$IMAGE_VERSION"
for containerID in "${containerIDs[@]}"
do
  echo "Removing container ID: $containerID"
  podman rm "$containerID"
done
