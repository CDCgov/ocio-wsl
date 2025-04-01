FROM docker.io/ubuntu:24.04

LABEL updated_at=2025-03-11

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

##############################################################################
# Install Linux based tools for various activities such as networking,
# certificate management, software engineering, and building other software.
##############################################################################
RUN apt-get update -q && apt-get install -y \
  autossh \
  ca-certificates \
  dnsutils \
  watch \
  curl \
  dnsperf \
  git \
  gpg \
  iperf3 \
  jq \
  nano \
  netcat-openbsd \
  podman \
  sudo \
  strace \
  rsync \
  unzip \
  wget \
  whois \
  tcpdump \

  # For python installation
  build-essential \
  libbz2-dev \
  libncurses5-dev \
  libgdbm-dev \
  libnss3-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libffi-dev \
  liblzma-dev \
  python3.12-venv \
  zlib1g-dev \

  # For R installation: https://github.com/asdf-community/asdf-r
  libcurl3-dev \
  gfortran \
  liblzma5 \
  libbz2-1.0 \
  libbz2-dev \
  xorg-dev \
  libbz2-dev \
  liblzma-dev \
  libpcre2-dev && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

###############################################################################
## Install the enterprise certificates into the operating system truststore
## to minimize the amount of SSL / TLS certificate problems for HTTP clients
## to drop or terminate a socket connection.
###############################################################################
# COPY config/bundle-ca.pem /usr/local/share/ca-certificates/enterprise-bundle.crt
# RUN cp /usr/local/share/ca-certificates/enterprise-bundle.crt /usr/lib/ssl/cert.pem && \
#   update-ca-certificates
RUN wget -q -O /usr/local/share/ca-certificates/enterprise-bundle.crt \
    https://raw.githubusercontent.com/cdcgov/ocio-certificate-infra/main/bundle-ca.pem && \
    cp /usr/local/share/ca-certificates/enterprise-bundle.crt /usr/lib/ssl/cert.pem && \
    update-ca-certificates
###############################################################################
## Install mise to install a variety of programming languages and command line
## tools. Users can find and install their own tools by following instructions
## on https://mise.jdx.dev/getting-started.html.
##
## To update these tools, users can run mise list to find all software installed to
## find the latest version, update the ~/.config/mise/config.toml file for the version
## they want, and run mise upgrade to install that version.
##
## To install mise into the /opt directory so that all users can use
## mise, we follow the instructions from this issue:
## https://github.com/jdx/mise/blob/main/packaging/mise/Dockerfile
###############################################################################
# Set environment variables to install tools globally
ENV MISE_DATA_DIR=/opt/mise
ENV XDG_DATA_HOME=/opt/mise
ENV MISE_CONFIG_DIR=/opt/mise/config
ENV PATH="/opt/mise/bin:/opt/mise/shims:$PATH"

# Install mise, the package manager for command line tools
RUN install -dm 755 /etc/apt/keyrings && \
  wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null && \
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
  apt update && \
  apt install -y mise && \
  mkdir -p /opt/mise/bin && \
  ln -s /usr/bin/mise /opt/mise/bin/mise && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy config file
COPY config/config.toml "${MISE_CONFIG_DIR}/config.toml"
COPY config/config.toml "/etc/mise/config.toml"

# Ensure mise is initialized for all users
RUN echo 'export PATH="/opt/mise/bin:/opt/mise/shims:$PATH"' >> /etc/skel/.bashrc && \
  echo 'export PATH="/opt/mise/bin:/opt/mise/shims:$PATH"' >> /root/.bashrc && \
  echo 'eval "$(mise activate bash)"' >> /etc/skel/.bashrc && \
  echo 'eval "$(mise activate bash)"' >> /root/.bashrc

# Ensure Python trusts the CDC root certificates, so that it can access internal 
# websites signed by CDC's certificate and cross firewalls using man-in-the-middle 
# certificate:
# The root certificate of Ubuntu is /etc/ssl/certs/ca-certificates.crt based on
# https://go.dev/src/crypto/x509/root_linux.go
ENV REQUESTS_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt'
ENV SSL_CERT_FILE='/etc/ssl/certs/ca-certificates.crt'

# Ensure NodeJS trusts the CDC root certificates, so that it can access internal 
# websites signed by CDC's certificate and cross firewalls using man-in-the-middle 
# certificate
ENV NODE_OPTIONS='--use-openssl-ca'

# Ensure curl trusts the CDC root certificates, so that it can access internal 
# websites signed by CDC's certificate and cross firewalls using man-in-the-middle 
# certificate
ENV CURL_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt'

# Ensure git trusts the CDC root certificates, so that it can access internal 
# websites signed by CDC's certificate and cross firewalls using man-in-the-middle 
# certificate
RUN git config --global http.sslcainfo '/etc/ssl/certs/ca-certificates.crt'

##############################################################################
## All other tools are in the folder: python requires special care to install.
## Install all other tools by running: mise upgrade
##
## There is a file limit to Github releases of 2GB:
##############################################################################
RUN mise use python@3.12.9 --global

##############################################################################
## Create skeleton bashrc files for users to use when they login to the
## container. These files will be copied to the user's home directory.
##############################################################################
COPY config/.bashrc /root/.bashrc
COPY config/.bashrc /etc/skel/.bashrc

COPY config/.bash_aliases /root/.bash_aliases
COPY config/.bash_aliases /etc/skel/.bash_aliases

##############################################################################
## Ensure DNS is working properly: 
## https://gist.github.com/ThePlenkov/6ecf2a43e2b3898e8cd4986d277b5ecf
##
## Make the resolv.conf file immutable so that wsl won't delete it on startup
## https://github.com/microsoft/wsl/issues/5420
##############################################################################
COPY config/wsl.conf /etc/wsl.conf

###########################################################################
## Copy helpful bash scripts over for testing the environment.
###########################################################################
COPY scripts/ /opt/scripts/

# Clean up the local repository of retrieved package files, useful only for
# local environments which don't have any cleanup mechanism.
RUN apt-get clean

# Start a shell when the container runs
CMD ["/bin/bash"]
