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

echo "Creating temporary export container from $IMAGE_NAME"
container_id=$(podman create "$IMAGE_NAME")

cleanup_export_container() {
  podman rm "$container_id" > /dev/null 2>&1 || true
}
trap cleanup_export_container EXIT

echo "Exporting image $container_id > $TAR_DIR/$WSL_NAME"
podman export "$container_id" > "$TAR_DIR/$WSL_NAME"

echo "Removing temporary export container $container_id"
podman rm "$container_id"
trap - EXIT
