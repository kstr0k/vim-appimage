#!/bin/sh
set -ue

git submodule update --init --depth 10 vim
cd vim
since=$(git log -1 --pretty=%cd @~1)
git fetch -j2 --shallow-since="$since" --no-tags origin tag "${vim_tag}" tag "${prev_vim_tag}"
git switch --detach "${vim_tag}"
