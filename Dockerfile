FROM docker.io/ubuntu:22.04

LABEL updated_at=2023-10-13

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

##############################################################################
## Ensure DNS is working properly: 
## https://gist.github.com/ThePlenkov/6ecf2a43e2b3898e8cd4986d277b5ecf
##
## Make the resolv.conf file immutable so that wsl won't delete it on startup
## https://github.com/microsoft/wsl/issues/5420
##############################################################################
COPY config/wsl.conf /etc/wsl.conf
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf

## Can't seem to make resolv.conf immutable. Writing a script fix-dns.sh instead.
## RUN chattr -f +i /etc/resolv.conf

RUN apt-get update -q

##############################################################################
# Install Linux based tools for various activities such as networking,
# certificate management, software engineering, and building other software.
##############################################################################
RUN apt-get update && apt-get install -y \
  autossh \
  ca-certificates \
  dnsutils \
  watch \
  curl \
  dnsperf \
  git \
  iperf3 \
  nano \
  netcat \
  rsync \
  unzip \
  wget \
  whois \
  tcpdump \
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
  zlib1g-dev

###############################################################################
## Install the enterprise certificates into the operating system truststore
## to minimize the amount of SSL / TLS certificate problems for HTTP clients
## to drop or terminate a socket connection.
###############################################################################
COPY config/bundle-ca.pem /usr/local/share/ca-certificates/enterprise-bundle.crt
RUN update-ca-certificates

###############################################################################
## Install asdf to install a variety of programming languages and command line
## tools. Users can find and install their own tools by following instructions
## on https://asdf-vm.com/manage/plugins.html.
##
## To update these tools, users can run asdf list-all <tool> such as python to
## find the latest version, update the ~/.tool-versions file for the version
## they want, and run asdf install to install that version.
###############################################################################
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1 && \
  echo ". $HOME/.asdf/asdf.sh" >> /root/.bashrc && \
  echo ". $HOME/.asdf/asdf.sh" >> /root/.zshrc

# Add asdf to profile, so it is available in `podman run`
ENV PATH="$PATH:/root/.asdf/bin"

# Add asdf shims to PATH, so installed executables can be run in this Dockerfile
ENV PATH="$PATH:/root/.asdf/shims"

RUN asdf plugin add awscli && \
    # asdf plugin add azure-cli && \
    asdf plugin add gradle && \
    asdf plugin add helm && \
    asdf plugin add java && \
    asdf plugin add kubectl && \
    asdf plugin add maven && \
    asdf plugin add nodejs && \
    asdf plugin add oc && \
    asdf plugin add pre-commit && \
    asdf plugin add podman https://github.com/tvon/asdf-podman.git && \
    asdf plugin add python && \
    asdf plugin add sbt && \
    asdf plugin add scala && \
    asdf plugin add steampipe && \
    asdf plugin add terraform && \
    asdf plugin add trivy

# # COPY config/.tool-versions "$PATH:/root/.asdf/.tool-versions"
# # RUN asdf install

RUN asdf install awscli 2.13.26 && \
    # asdf install azure-cli 2.53.0 && \
    asdf install gradle 8.2.1 && \
    asdf install helm 3.12.3 && \
    asdf install java temurin-11.0.20+8 && \
    asdf install kubectl 1.28.2 && \
    asdf install maven 3.9.5 && \
    asdf install nodejs 18.18.1 && \
    asdf install oc 4.13.16 && \
    asdf install podman 4.7.1 && \
    asdf install pre-commit 3.3.3 && \
    asdf install python 3.11.6 && \
    asdf install sbt 1.7.1 && \
    asdf install scala 3.1.3 && \
    asdf install steampipe 0.20.12 && \
    asdf install terraform 1.5.3 && \
    asdf install trivy 0.45.0

RUN asdf global awscli 2.13.26 && \
    # asdf global azure-cli 2.53.0 && \
    asdf global gradle 8.2.1 && \
    asdf global helm 3.12.3 && \
    asdf global java temurin-11.0.20+8 && \
    asdf global kubectl 1.28.2 && \
    asdf global maven 3.9.5 && \
    asdf global nodejs 18.18.1 && \
    asdf global oc 4.13.16 && \
    asdf global podman 4.7.1 && \
    asdf global pre-commit 3.3.3 && \
    asdf global python 3.11.6 && \
    asdf global sbt 1.7.1 && \
    asdf global scala 3.1.3 && \
    asdf global steampipe 0.20.12 && \
    asdf global terraform 1.5.3 && \
    asdf global trivy 0.45.0

###########################################################################
## Update bashrc with auto branch complete so that the branch shows up in  
## the folder when using git and branches... this indication prevents
## accidental check-ins or deletions.
###########################################################################
RUN echo 'parse_git_branch() {' >> /root/.bashrc && \
  echo '    git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \(.*\)/ (\1)/"' >> /root/.bashrc && \
  echo '}' >> /root/.bashrc && \
  echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$(parse_git_branch)\$ "' >> /root/.bashrc

###########################################################################
## Copy helpful bash scripts over for testing the environment.
###########################################################################
COPY scripts/add-user.sh opt/scripts/add-user.sh
COPY scripts/check-google.sh opt/scripts/check-google.sh
COPY scripts/fix-time.sh opt/scripts/fix-time.sh

# Clean up the local repository of retrieved package files, useful only for
# local environments which don't have any cleanup mechanism.
RUN apt-get clean

# Start a shell when the container runs
CMD ["/bin/bash"]