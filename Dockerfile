FROM docker.io/ubuntu:24.04

LABEL updated_at=2024-08-31

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
  iperf3 \
  jq \
  nano \
  netcat-openbsd \
  podman \
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
COPY config/bundle-ca.pem /usr/local/share/ca-certificates/enterprise-bundle.crt
RUN cp /usr/local/share/ca-certificates/enterprise-bundle.crt /usr/lib/ssl/cert.pem && \
  update-ca-certificates

###############################################################################
## Install asdf to install a variety of programming languages and command line
## tools. Users can find and install their own tools by following instructions
## on https://asdf-vm.com/manage/plugins.html.
##
## To update these tools, users can run asdf list-all <tool> such as python to
## find the latest version, update the ~/.tool-versions file for the version
## they want, and run asdf install to install that version.
###############################################################################
ENV ASDF_VERSION="0.14.1"
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "v${ASDF_VERSION}" && \
  echo ". $HOME/.asdf/asdf.sh" >> /root/.bashrc && \
  echo ". $HOME/.asdf/asdf.sh" >> /root/.zshrc

COPY config/.tool-versions /root/.tool-versions

# Add asdf to profile, so it is available in `podman run`
ENV PATH="$PATH:/root/.asdf/bin"

# Add asdf shims to PATH, so installed executables can be run in this Dockerfile
ENV PATH="$PATH:/root/.asdf/shims"

# Ensure Python trusts the CDC root certificates, so that it can access internal 
# websites signed by CDC's certificate and cross firewalls using man-in-the-middle 
# certificate
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
## /opt/scripts/add-extra-tools.sh
##
## There is a file limit to Github releases of 2GB:
##############################################################################
RUN asdf plugin add python && asdf install && asdf global python 3.12.5

###########################################################################
## Update bashrc with auto branch complete so that the branch shows up in  
## the folder when using git and branches... this indication prevents
## accidental check-ins or deletions.
###########################################################################
RUN printf 'parse_git_branch() {\n  git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \\(.*\\)/(\\1)/"\n}\n' >> /root/.bashrc && \
  printf "PS1='\${debian_chroot:+(\$debian_chroot)}\[\\\\033[01;32m\\\\]\u@\\h\\[\\\\033[00m\\\\]:\\[\\\\033[01;35m\\\\]\w\[\\\\033[01;31m\\\\]\$(parse_git_branch)\[\\\\033[00m\\\\]\\$ '\n" >> /root/.bashrc && \
  printf "alias python=python3\n" >> /root/.bashrc && \

###########################################################################
## Podman requires knowing which container registries to pull from
## Provide a list of options for the registries.
###########################################################################
  echo "unqualified-search-registries = ['imagehub.cdc.gov:6989', 'registry.access.redhat.com', 'docker.io', 'registry.centos.org', 'registry.fedoraproject.org']" \
    >> /etc/containers/registries.conf

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
