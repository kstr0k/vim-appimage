#!/bin/sh
set -ue
sudo apt update && sudo apt install -y \
  libfuse2 \
  autoconf \
  lcov \
  gettext \
  libcanberra-dev \
  libperl-dev \
  python2-dev python3-dev \
  liblua5.4-dev lua5.4 \
  ruby-dev \
  tcl-dev \
  cscope \
  libgtk-3-dev \
  desktop-file-utils \
  libtool-bin \
  at-spi2-core \
  libsodium-dev
