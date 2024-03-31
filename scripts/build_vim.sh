#!/bin/bash
#
# build vim
#

set -e

script_dir=$(dirname "$(readlink -f "$0")")
SRCDIR=$script_dir/../vim/src

FEATURES=huge
export CFLAGS="-Wno-deprecated-declarations"

typeset -a CFG_OPTS
CFG_OPTS+=( "--enable-perlinterp" )
CFG_OPTS+=( "--disable-pythoninterp" )
CFG_OPTS+=( "--enable-python3interp=dynamic" )
CFG_OPTS+=( "--with-python3-stable-abi=3.8" )
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

# Build Vim or GVim
build_vim() (  # args: vim_or_gvim additional_configure_opts...
local vim; vim=$1; shift
cd "${SRCDIR}"
rm -rf "$vim"
SHADOWDIR="$vim" make -e shadow
cd "$vim"
./configure --with-features=$FEATURES "${CFG_OPTS[@]}" "$@"
make -j$NPROC
)

apply_patches
build_vim vim  --enable-fail-if-missing --enable-gui=no --without-x
build_vim gvim --enable-fail-if-missing --enable-gui=gtk3
