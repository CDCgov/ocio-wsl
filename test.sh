#!/usr/bin/env bash

set -eu

podman run -t localhost/ubuntu-22.04-cdc bash -c "python --version"
podman run -t localhost/ubuntu-22.04-cdc bash -c "bash /opt/scripts/add-extra-tools.sh"