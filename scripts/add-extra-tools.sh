#!/usr/bin/env bash

set -eu

## Azure CLI's default asdf forces a python version, while this rewritten version does not.
mise plugins install https://github.com/boris-ning-usds/asdf-azure-cli --force
mise upgrade --env /opt/mise/config/config.toml

mise list
