#!/usr/bin/env bash

set -eu

ALL_IMAGE_NAMES=("ubuntu-24.04-cdc" "fedora-43-cdc")

DISTRO="${1:-all}"
case "$DISTRO" in
  ubuntu) IMAGE_NAMES=("ubuntu-24.04-cdc") ;;
  fedora) IMAGE_NAMES=("fedora-43-cdc") ;;
  all)    IMAGE_NAMES=("${ALL_IMAGE_NAMES[@]}") ;;
  *)
    echo "Usage: $0 [ubuntu|fedora|all]"
    exit 1
    ;;
esac

for IMAGE_NAME in "${IMAGE_NAMES[@]}"; do
  echo "--- Cleaning up $IMAGE_NAME ---"

  # Stop any running containers for this image
  running=$(podman container ls --filter "ancestor=$IMAGE_NAME" --format "{{.ID}}" 2>/dev/null || true)
  if [ -n "$running" ]; then
    echo "Stopping running containers..."
    echo "$running" | xargs podman stop
  fi

  # Remove all containers (running or stopped) associated with this image
  all_containers=$(podman container ls -a | grep -i "$IMAGE_NAME" | awk '{print $1}' || true)
  if [ -n "$all_containers" ]; then
    echo "Removing containers..."
    echo "$all_containers" | xargs podman rm -f
  else
    echo "No containers found for $IMAGE_NAME."
  fi

  # Remove the image itself
  if podman image exists "$IMAGE_NAME" 2>/dev/null; then
    echo "Removing image $IMAGE_NAME..."
    podman rmi "$IMAGE_NAME"
  else
    echo "Image $IMAGE_NAME not found, skipping."
  fi
done

# Remove dangling images (untagged layers left behind by builds)
dangling=$(podman images --filter dangling=true --quiet 2>/dev/null || true)
if [ -n "$dangling" ]; then
  echo "--- Removing dangling images ---"
  echo "$dangling" | xargs podman rmi
fi

# Remove exported .wsl files from the images directory
echo "--- Cleaning up exported .wsl files ---"
for IMAGE_NAME in "${IMAGE_NAMES[@]}"; do
  wsl_file="$PWD/images/${IMAGE_NAME}.wsl"
  if [ -f "$wsl_file" ]; then
    echo "Removing $wsl_file"
    rm "$wsl_file"
  fi
done

# Remove checksums and manifest if all distros were cleaned
if [[ "$DISTRO" == "all" ]]; then
  for artifact in "$PWD/images/checksums.txt" "$PWD/images/manifest.json"; do
    if [ -f "$artifact" ]; then
      echo "Removing $artifact"
      rm "$artifact"
    fi
  done
fi

echo "--- Done ---"
