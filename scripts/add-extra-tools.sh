#!/usr/bin/env bash

set -eu

asdf plugin add java
asdf plugin add nodejs
asdf plugin add helm
asdf plugin add gradle
asdf plugin add kubectl
asdf plugin add maven
asdf plugin add pre-commit
asdf plugin add sbt
asdf plugin add scala
asdf plugin add steampipe
asdf plugin add trivy
asdf plugin add yarn

asdf install