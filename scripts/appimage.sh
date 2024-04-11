#!/bin/bash

set -e

unsorted_uniq() {
  awk '{x=$0; sub(/=.*$/, "", x);if(!seen[x]++){print $0}}'
}

patch_desktop_files()
(
	# Remove duplicate keys from desktop file. This might occure while localisation
	# for the desktop file is progressing.
	cd "${BUILD_BASE}"
	unsorted_uniq <"${VIM_DIR}/runtime/${LOWERAPP}".desktop >"${LOWERAPP}".desktop

	if [ "${LOWERAPP}" = vim ]; then
		sed -i 's/^Icon=gvim/Icon=vim/' "${LOWERAPP}".desktop
	fi
	png=$(find "${VIM_DIR}"/runtime -xdev -name 'vim48x48.png' -print -quit)
	cp "$png" "${LOWERAPP}".png
)

deploy_pkg_copyright() {
  local dst lib docdir copyfile
  dst=$1; lib=$2; shift 2
  docdir=usr/share/doc/"$lib"
  copyfile="$docdir"/copyright
  if [ -r /"$copyfile" ]; then
    mkdir -p "$dst"/"$docdir"
    cp -a /"$copyfile" "$dst"/"$copyfile"
  fi
}
deploy_copyrights() {
  local dst lib
  dst=$1; shift
  find "$dst"/usr/lib -type f |
    sed -ne '/\.so$\|\.so\./{ s!$!$!; s!.*/!!p }' |
    grep -f - /var/lib/dpkg/info/*.list |
    sed  -e 's!\.list:.*!!; s!.*/!!; s!:.*!!' |
    LC_ALL=C sort -u |
    while IFS= read -r lib; do
      deploy_pkg_copyright "$dst" "$lib"
    done
}

extract_appimage() (  # args: appimg appdir
  local appimg appdir
  appimg=$(readlink -f "$1"); appdir=$2; shift 2
  chmod u+x "$appimg"
  local d; d=$(mktemp -d)
  (cd "$d"; "$appimg" --appimage-extract >/dev/null)
  mv "$d"/squashfs-root "$appdir"
  rmdir "$d"
)

make_appimage()
(
	cd "${BUILD_BASE}"

	[ "$APP" = GVim ] && PLUGIN='--plugin gtk'

	cp "$script_dir"/../assets/AppRun \
	   "$script_dir"/../assets/AppRun.extracted \
	   "${APP}".AppDir/

	LDAI_OUTPUT="$APPIMG_FNAME" DISABLE_COPYRIGHT_FILES_DEPLOYMENT=1 ../tools/linuxdeploy \
		--appdir "$APP.AppDir" \
		-d "${LOWERAPP}.desktop" \
		-i "${LOWERAPP}.png" \
		${PLUGIN:-} \

	deploy_copyrights "$APP".AppDir

	../tools/appimagetool \
          --runtime-file "${LDAI_RUNTIME_FILE}" \
          ${LDAI_UPDATE_INFORMATION:+-u "${LDAI_UPDATE_INFORMATION}"} \
          --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 12 --mksquashfs-opt -b --mksquashfs-opt 256k --mksquashfs-opt -no-progress \
          "$APP".AppDir "$APPIMG_FNAME"
)

gen_release_notes() (
  # Github Release Notes
  [ -n "$GITHUB_ACTIONS" ] || return 0
  RLS_BODY="$script_dir/../release.body"
  ! [ -e "$RLS_BODY" ] || return 0
  . "$script_dir"/release_notes.sh > "$RLS_BODY"
)

make_install() {
# Prepare source files
patch_desktop_files
# uses the shadowdir from build_vim.sh
make -C "${VIM_DIR}"/src/"${LOWERAPP}" install DESTDIR="${BUILD_BASE}/${APP}.AppDir" >/dev/null
}

compute_glibc_version() {
  find "${VIM_DIR}" -type f -executable -exec nm -j -D {} + 2>/dev/null | sed -ne '/@GLIBC_2[.]/{ s/.*@GLIBC_//; /^2[.][0-9][.]/d; /^2[.][0-9]$/d; p }' | sort --version-sort -r -u | head -n 1
  #/lib/x86_64-linux-gnu/libc.so.6 | sed -ne 's/.*GLIBC \(2\.[0-9][0-9]*\).*/\1/p;q'  # system version might be higher than actually required
}

setup_app_build() {
  BUILD_BASE=$script_dir/../appimage-${APP}
  mkdir -p "$BUILD_BASE"
  LOWERAPP=${APP,,}
  APPIMG_FNAME=${APP}-${APPIMG_FNAME_SFX}

  export LDAI_RUNTIME_FILE="$script_dir"/../tools/appimage-runtime
  export LDAI_UPDATE_INFORMATION
  if [ -n "${MYOWNER:-}" ]; then
    LDAI_UPDATE_INFORMATION="gh-releases-zsync|$MYOWNER|$MYREPO|latest|$APP-*x86_64.AppImage.zsync"
  fi
  # ^ linuxdeploy's internal appimage plugin uses these
}

script_dir=$(dirname "$(readlink -f "$0")")

VIM_DIR=$script_dir/../vim
: "${GLIBC:=$(compute_glibc_version)}"

# should use tag if available, else use 7-hexdigit hash
: "${VERSION:="$(git -C "${VIM_DIR}" describe --tags --abbrev=0 || git describe --always)"}"
: "${APPIMG_FNAME_SFX:=${VERSION}.glibc${GLIBC}-$(arch).AppImage}"

(cd tools; "$script_dir"/download-tools.sh)
gen_release_notes

for APP; do
  setup_app_build
  make_install
  make_appimage
done
