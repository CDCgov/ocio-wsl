#!/usr/bin/env bash

set -eu

podman run -t localhost/ubuntu-24.04-cdc bash -c "python --version && which python"
podman run -t localhost/ubuntu-24.04-cdc bash -c "python3 --version && which python3"
podman run -t localhost/ubuntu-24.04-cdc bash -c "bash /opt/scripts/add-extra-tools.sh && asdf install"
podman run -t localhost/ubuntu-24.04-cdc bash -c "uname -a && cat /etc/os-release"
podman run -t localhost/ubuntu-24.04-cdc bash -c "asdf --help"
podman run -t localhost/ubuntu-24.04-cdc bash -c "ls -l /opt"
podman run -t localhost/ubuntu-24.04-cdc bash -c "cat ~/.bashrc"