# Installing R

R is not included in the default tool list because the mise R plugin compiles R from source, which takes a while and needs extra system packages.

## 1. Install the build dependencies

For Fedora:

```bash
sudo dnf install -y libcurl-devel gcc-gfortran xz-libs bzip2-libs \
  libX11-devel libXt-devel xorg-x11-proto-devel pcre2-devel
```

For Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y build-essential libcurl4-openssl-dev gfortran \
  liblzma-dev liblzma5 libbz2-dev libbz2-1.0 xorg-dev libpcre2-dev
```

## 2. Install R with mise

Run this as your normal user, not with `sudo`:

```bash
ASDF_CONCURRENCY="$(nproc)" mise use asdf:mise-plugins/mise-r --global
```

The plugin compiles with a single job by default, which can take a long time. `ASDF_CONCURRENCY="$(nproc)"` tells it to use all available CPUs. You can drop it if you'd rather keep your machine responsive during the build.

## 3. Verify the installation

```bash
R --version | head -1
mise ls
```
