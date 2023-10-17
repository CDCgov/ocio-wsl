#!/usr/bin/env bash

set -eu

########################################################################
## Logging into WSL for the first time, you'll be using the root user.
##
## It is a good idea to create a separate user/password altogether.
########################################################################

adduser -G wheel "${USERNAME}" && \
  echo -e "[user]\ndefault=${USERNAME}" >> /etc/wsl.conf && \
  echo "${PASSWORD}" | passwd --stdin "${USERNAME}"