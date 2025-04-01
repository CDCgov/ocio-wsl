#!/usr/bin/env bash

set -eu

## Install all the basic tools that serves as the foundation for the rest of the tools
## mise does not provide ordering, so we have to install them manually in the order we want
mise install python --env /opt/mise/config/config.toml
mise install nodejs --env /opt/mise/config/config.toml
mise install java --env /opt/mise/config/config.toml
mise install golang --env /opt/mise/config/config.toml
mise install r --env /opt/mise/config/config.toml
mise install rust --env /opt/mise/config/config.toml

## Azure CLI's default asdf forces a python version, while this rewritten version does not.
mise plugins install https://github.com/boris-ning-usds/asdf-azure-cli --force

## Install the rest of the tools as dependencies should already be installed
mise upgrade --env /opt/mise/config/config.toml

mise list
