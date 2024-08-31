#!/usr/bin/env bash

set -eu

asdf plugin add actionlint
asdf plugin add awscli
asdf plugin add azure-cli https://github.com/boris-ning-usds/asdf-azure-cli
asdf plugin add checkov
asdf plugin add golang
asdf plugin add gradle
asdf plugin add helm
asdf plugin add java
asdf plugin add kubectl
asdf plugin add maven
asdf plugin add nodejs
asdf plugin add oc
asdf plugin add pre-commit
asdf plugin add r
asdf plugin add ripgrep
asdf plugin add rust
asdf plugin add sbt
asdf plugin add scala
asdf plugin add steampipe
asdf plugin add terraform
asdf plugin add trivy
asdf plugin add yarn

asdf install
