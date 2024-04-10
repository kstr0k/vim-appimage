#!/bin/sh
set -ue

gh_download_release() {
  local repo rls dl fname
  repo=$1; rls="$2"; dl=$3; fname=${4:-$dl}; set --

  [ ! -e "$fname" ] || return 0
  gh release download "$rls" -R "$repo" -p "$dl" -O "$fname" ||
    wget --no-verbose -O "$fname" "https://github.com/$repo/releases/download/$rls/$dl"
}

gh_download_raw() {
  local repo ref fname
  repo=$1; ref=$2; fname=${3:-${repo##*/}}; set --

  [ ! -e "$fname" ] || return 0
  # undocumented 'raw' but 'raw+json' returns base64
  gh >"$fname" api -H 'Accept: application/vnd.github.raw' "/repos/$repo/contents/$fname?ref=$ref" ||
    wget --no-verbose -O "$fname" "https://raw.githubusercontent.com/$repo/$ref/$fname"
}

gh_download_release linuxdeploy/linuxdeploy continuous linuxdeploy-x86_64.AppImage linuxdeploy
gh_download_release AppImage/appimagetool continuous appimagetool-x86_64.AppImage appimagetool
gh_download_release AppImage/type2-runtime continuous runtime-x86_64 appimage-runtime

gh_download_raw 'linuxdeploy/linuxdeploy-plugin-gtk' master 'linuxdeploy-plugin-gtk.sh'

chmod u+x *
