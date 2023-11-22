#!/usr/bin/env bash

set -eu

podman run -t localhost/ubuntu-22.04-cdc bash -c "python --version && which python"
podman run -t localhost/ubuntu-22.04-cdc bash -c "python3 --version && which python3"
podman run -t localhost/ubuntu-22.04-cdc bash -c "asdf global python 3.11.6 && python3 --version"
# podman run -t localhost/ubuntu-22.04-cdc bash -c "bash /opt/scripts/add-extra-tools.sh"