#!/usr/bin/env bash

set -eu

## Install all the basic tools that serves as the foundation for the rest of the tools
## mise does not provide ordering, so we have to install them manually in the order we want
if [ ! -f "${HOME}/.config/mise/config.toml" ]; then
  echo "Missing ${HOME}/.config/mise/config.toml. Run the image's first-login setup first."
  exit 1
fi
mise install nodejs
mise install java
mise install golang
# Use curl workaround due to rust docs download timing out after 30 seconds on zscalar connection
export RUSTUP_USE_CURL=1
mise install rust

## Install the rest of the tools as dependencies should already be installed
mise upgrade

mise list
