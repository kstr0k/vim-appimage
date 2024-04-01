#!/bin/sh
set -ue

export DEBIAN_FRONTEND=noninteractive

apt update && apt install -y \
  autoconf \
  lcov \
  gettext \
  libcanberra-dev \
  libperl-dev \
  python-dev \
  python3.8-dev \
  liblua5.3-dev \
  lua5.3 \
  ruby-dev \
  tcl-dev \
  cscope \
  libgtk-3-dev \
  desktop-file-utils \
  libtool-bin \
  at-spi2-core \
  libsodium-dev
