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

DISTRO="${1:-ubuntu}"
TAR_DIR="$PWD/images"
mkdir -p "$TAR_DIR"

case "$DISTRO" in
  ubuntu)
    IMAGE_NAME="ubuntu-24.04-cdc"
    DOCKERFILE="Dockerfile.ubuntu"
    ;;
  fedora)
    IMAGE_NAME="fedora-43-cdc"
    DOCKERFILE="Dockerfile.fedora"
    ;;
  *)
    echo "Unknown distro: $DISTRO. Supported values: ubuntu, fedora"
    exit 1
    ;;
esac

WSL_NAME="${IMAGE_NAME}.wsl"

echo "Building image $IMAGE_NAME from $DOCKERFILE"
podman build . -f "$DOCKERFILE" -t "$IMAGE_NAME"

echo "Running image $IMAGE_NAME"
podman run --privileged -t "$IMAGE_NAME" sh -c echo
containerID=$(podman container ls -a | grep -i "$IMAGE_NAME" | tail -1 | awk '{print $1}') # last one is most current

echo "Exporting image $containerID > $TAR_DIR/$WSL_NAME"
podman export "$containerID" > "$TAR_DIR/$WSL_NAME"

# Remove the image from podman container storage to avoid piling up of containers
containerIDs=($(podman container ls -a | grep -i "$IMAGE_NAME" | awk '{print $1}' | tr '\n' ' '))
echo "Removing containers with image: $IMAGE_NAME"
for containerID in "${containerIDs[@]}"
do
  echo "Removing container ID: $containerID"
  podman rm "$containerID"
done
