#!/bin/bash
#
# build vim
#

set -e

script_dir="$(cd "$(dirname "$0")" && pwd)"
SRCDIR=$script_dir/../vim/src

FEATURES=huge
export CFLAGS="-Wno-deprecated-declarations"

typeset -a CFG_OPTS
CFG_OPTS+=( "--enable-perlinterp" )
CFG_OPTS+=( "--enable-pythoninterp" )
CFG_OPTS+=( "--with-python3-stable-abi" )
CFG_OPTS+=( "--enable-rubyinterp" )
CFG_OPTS+=( "--enable-luainterp" )
CFG_OPTS+=( "--enable-tclinterp" )
CFG_OPTS+=( "--prefix=/usr" )

NPROC=$(getconf _NPROCESSORS_ONLN)

# Apply experimental patches
apply_patches() (
shopt -s nullglob
cd "${SRCDIR}"/..
for i in ../patch/*.patch; do git apply -v "$i"; done
)


# Build Vim - no X11
build_vim() (
cd "${SRCDIR}"
rm -rf vim
SHADOWDIR=vim make -e shadow
cd vim
ADDITIONAL_ARG="--without-x --enable-gui=no --enable-fail-if-missing"
./configure --with-features=$FEATURES "${CFG_OPTS[@]}" $ADDITIONAL_ARG
make -j$NPROC
)

# Build GVim
build_gvim() (
cd "${SRCDIR}"
rm -rf gvim
SHADOWDIR=gvim make -e shadow
cd gvim
ADDITIONAL_ARG="--enable-fail-if-missing"
CFG_OPTS+=( "--enable-gui=gtk3" )
./configure --with-features=$FEATURES "${CFG_OPTS[@]}" $ADDITIONAL_ARG
make -j$NPROC
)

apply_patches
build_vim
build_gvim
