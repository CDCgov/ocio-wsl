#!/usr/bin/env bash

set -e

DISTRO="${1:-ubuntu}"

case "$DISTRO" in
  ubuntu)
    IMAGE_NAME="ubuntu-24.04-cdc"
    ;;
  fedora)
    IMAGE_NAME="fedora-43-cdc"
    ;;
  *)
    echo "Usage: $0 [ubuntu|fedora]"
    exit 1
    ;;
esac

CONTAINER_NAME="${IMAGE_NAME}-test"

# Start the container in detached mode if it's not already running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
  echo "Starting container ${CONTAINER_NAME}..."
  podman run --privileged -dt --name "${CONTAINER_NAME}" "localhost/${IMAGE_NAME}" bash
else
  echo "Reusing existing container ${CONTAINER_NAME}..."
fi

PASS=()
FAIL=()

run_test() {
  local label="$1"
  local cmd="$2"
  echo "--- $label ---"
  if podman exec "${CONTAINER_NAME}" bash -c "$cmd" 2>&1; then
    PASS+=("$label")
  else
    FAIL+=("$label")
  fi
}

run_test "os-release"          "uname -a && cat /etc/os-release"
run_test "python3"             "python3 --version && which python3"
run_test "add-extra-tools"     "bash /opt/scripts/add-extra-tools.sh"
run_test "mise list"           "mise ls"
run_test "mise doctor"         "mise doctor"
run_test "R"                   "R --version | head -1"
run_test "opt layout"          "ls -l /opt"
run_test "bashrc"              "cat ~/.bashrc"
run_test "wsl-distribution"    "cat /etc/wsl-distribution.conf"
run_test "oobe script"         "test -x /etc/oobe.sh"
run_test "cdc icon"            "test -f /usr/lib/wsl/cdc.ico"
run_test "terminal profile"    "test -f /usr/lib/wsl/terminal-profile.json"
run_test "scripts executable"  "ls /opt/scripts/*.sh | xargs -I{} test -x {}"

echo ""
echo "=========================================="
echo " Test Report - ${IMAGE_NAME}"
echo "=========================================="
for t in "${PASS[@]}"; do
  echo "  PASS  $t"
done
for t in "${FAIL[@]}"; do
  echo "  FAIL  $t"
done
echo "------------------------------------------"
echo "  ${#PASS[@]} passed, ${#FAIL[@]} failed"
echo "=========================================="

echo ""
echo "To inspect: podman exec -it ${CONTAINER_NAME} bash"
echo "To clean up: bash cleanup.sh ${DISTRO}"

[ ${#FAIL[@]} -eq 0 ]
