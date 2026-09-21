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
run_test "mise executable"     "mise --version"
run_test "mise user template"  "test -f /etc/skel/.config/mise/config.toml"
run_test "no system config"    "test ! -e /etc/mise/config.toml"
run_test "uid 1000 available"  "test -z \"\$(getent passwd 1000)\""
run_test "rootless podman prerequisites" "for command_name in podman newuidmap newgidmap fuse-overlayfs setcap; do command -v \"\$command_name\" >/dev/null; done"
run_test "rootless podman user setup" "id podman_test >/dev/null 2>&1 || useradd --uid 2000 --create-home podman_test; sed -i '/^podman_test:/d' /etc/subuid /etc/subgid; uidmap_path=\$(command -v newuidmap); gidmap_path=\$(command -v newgidmap); test -u \"\$uidmap_path\" || setcap -r \"\$uidmap_path\" 2>/dev/null || true; test -u \"\$gidmap_path\" || setcap -r \"\$gidmap_path\" 2>/dev/null || true; /opt/scripts/configure-rootless-podman.sh podman_test; awk -F: '\$1 == \"podman_test\" && \$3 >= 65536 { found = 1 } END { exit !found }' /etc/subuid; awk -F: '\$1 == \"podman_test\" && \$3 >= 65536 { found = 1 } END { exit !found }' /etc/subgid; test -u \"\$uidmap_path\" || getcap \"\$uidmap_path\" | grep -q cap_setuid; test -u \"\$gidmap_path\" || getcap \"\$gidmap_path\" | grep -q cap_setgid"
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
