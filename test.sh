#!/usr/bin/env bash

set -eu

# Define the container name
CONTAINER_NAME="ubuntu-24.04-cdc-test"

# Start the container in detached mode if it's not already running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
  echo "Starting container ${CONTAINER_NAME}..."
  podman run -dt --name "${CONTAINER_NAME}" localhost/ubuntu-24.04-cdc bash
else
  echo "Reusing existing container ${CONTAINER_NAME}..."
fi

# Function to run a command inside the container
run_test() {
  echo "Running: $1"
  podman exec "${CONTAINER_NAME}" bash -c "$1"
}

# Run tests inside the existing container
run_test "python3 --version && which python3"
run_test "bash /opt/scripts/add-extra-tools.sh"
run_test "uname -a && cat /etc/os-release"
run_test "mise ls"
run_test "mise doctor"
run_test "ls -l /opt"
run_test "cat ~/.bashrc"

# Optionally, keep the container running for debugging
echo "Tests complete. To manually inspect, run: podman exec -it ${CONTAINER_NAME} bash"
echo "To stop and remove the container, run: podman stop ${CONTAINER_NAME} && podman rm ${CONTAINER_NAME}"
