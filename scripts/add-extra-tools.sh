#!/usr/bin/env bash

set -eu

mise plugins install https://github.com/boris-ning-usds/asdf-azure-cli --force
mise upgrade --env /opt/mise/config/config.toml

mise list
