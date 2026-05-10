#!/usr/bin/env bash

set -eu

## Install all the basic tools that serves as the foundation for the rest of the tools
## mise does not provide ordering, so we have to install them manually in the order we want
mise install nodejs --env /etc/mise/config.toml
mise install java --env /etc/mise/config.toml
mise install golang --env /etc/mise/config.toml
mise install "asdf:mise-plugins/mise-r" --env /etc/mise/config.toml

# Use curl workaround due to rust docs download timing out after 30 seconds on zscalar connection
export RUSTUP_USE_CURL=1
mise install rust --env /etc/mise/config.toml

## Install the rest of the tools as dependencies should already be installed
mise upgrade --env /etc/mise/config.toml

mise list
