#!/bin/bash

set -e

patch_desktop_files()
(
	# Remove duplicate keys from desktop file. This might occure while localisation
	# for the desktop file is progressing.
	cd "${SOURCE_DIR}/runtime"
	mv ${LOWERAPP}.desktop ${LOWERAPP}.desktop.orig
	awk '{x=$0; sub(/=.*$/, "", x);if(!seen[x]++){print $0}}' ${LOWERAPP}.desktop.orig > ${LOWERAPP}.desktop
	rm ${LOWERAPP}.desktop.orig

	if [[ "$LOWERAPP" == "vim" ]]; then
		sed -i "s/^Icon=gvim/Icon=vim/" ${LOWERAPP}.desktop
	fi
	find . -xdev -name "vim48x48.png" -exec cp {} "${LOWERAPP}.png" \;
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
  find "$dst"/usr/lib -type f -name '*.so*' -printf '*/%f\n' |
    xargs -d'\n' dpkg-query -S |
    sed -e 's@:.*@@' | uniq | LC_ALL=C sort -u |
    while IFS= read -r lib; do
      deploy_pkg_copyright "$dst" "$lib"
    done
}

make_appimage()
(
	cd "${BUILD_BASE}"
	[ -x linuxdeploy.appimage ] ||
		wget -O linuxdeploy.appimage -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
	chmod +x linuxdeploy.appimage

	if [ "$APP" = GVim ]; then
		test -x linuxdeploy-plugin-gtk.sh ||
			wget -q 'https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh'
		chmod +x linuxdeploy-plugin-gtk.sh
		PLUGIN='--plugin gtk'
	fi

	cp "$script_dir"/../assets/AppRun \
	   "$script_dir"/../assets/AppRun.extracted \
	   "${APP}".AppDir/

	export LDAI_UPDATE_INFORMATION="gh-releases-zsync|vim|vim-appimage|latest|$APP-*x86_64.AppImage.zsync"
	# ^ linuxdeploy's internal appimage plugin uses these

	LDAI_OUTPUT="$APPIMG_FNAME" DISABLE_COPYRIGHT_FILES_DEPLOYMENT=1 ./linuxdeploy.appimage \
		--appdir "$APP.AppDir" \
		-d "${SOURCE_DIR}/runtime/${LOWERAPP}.desktop" \
		-i "${SOURCE_DIR}/runtime/${LOWERAPP}.png" \
		${PLUGIN:-} \
		--output appimage

	chmod u+x "$APPIMG_FNAME"
	# somehow linuxdeploy manages to change the AppDir *after* packing it: extract the AppImage
	rm -rf squashfs-root
	./"$APPIMG_FNAME" --appimage-extract >/dev/null
	mv "$APPIMG_FNAME" "${APPIMG_FNAME%.*}".ldai  # available for debugging

	deploy_copyrights squashfs-root

	[ -e appimagetool ] ||
		wget -O appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
	chmod u+x appimagetool
	./appimagetool -u "$LDAI_UPDATE_INFORMATION" --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 12 --mksquashfs-opt -b --mksquashfs-opt 1M --mksquashfs-opt -no-progress squashfs-root "$APPIMG_FNAME"
)

github_actions_deploy()
(
		cd -P "${BUILD_BASE}"
		# Copy artifacts to $GITHUB_WORKSPACE
		printf '%s\n' "Copy $BUILD_BASE/$APPIMG_FNAME -> $GITHUB_WORKSPACE"
		cp "$APPIMG_FNAME" "$APPIMG_FNAME".zsync "$GITHUB_WORKSPACE"
	
		# Github Release Notes
		RLS_BODY="$GITHUB_WORKSPACE/release.body"
		[ -e "$RLS_BODY" ] || (. "$script_dir"/release_notes.sh > "$RLS_BODY")
)

make_and_deploy() (
# uses the shadowdir from build_vim.sh
cd vim/src/"$LOWERAPP"

# Prepare source files
patch_desktop_files
make install DESTDIR="${BUILD_BASE}/${APP}.AppDir" >/dev/null

# Create Appimage
make_appimage

# Perform Github Deployment
if [ -n "$GITHUB_ACTIONS" ]; then
	github_actions_deploy
fi
)

compute_glibc_version() {
  find "${SOURCE_DIR}" -type f -executable -exec nm -j -D {} + 2>/dev/null | sed -ne '/@GLIBC_2[.]/{ s/.*@GLIBC_//; /^2[.][0-9][.]/d; /^2[.][0-9]$/d; p }' | uniq | sort --version-sort -r -u | head -n 1
  #/lib/x86_64-linux-gnu/libc.so.6 | sed -ne 's/.*GLIBC \(2\.[0-9][0-9]*\).*/\1/p;q'  # system version might be higher than actually required
}

script_dir=$(dirname "$(readlink -f "$0")")

[ "$#" != 0 ] || set -- GVim

SOURCE_DIR=$script_dir/../vim
BUILD_BASE=$script_dir/../build
mkdir -p "$BUILD_BASE"
: "${GLIBC:=$(compute_glibc_version)}"

# should use tag if available, else use 7-hexdigit hash
: "${VERSION:="$(git -C "${SOURCE_DIR}" describe --tags --abbrev=0 || git describe --always)"}"
: "${APPIMG_FNAME_SFX:=${VERSION}.glibc${GLIBC}-$(arch).AppImage}"

for APP; do
  LOWERAPP=${APP,,}
  APPIMG_FNAME=${APP}-${APPIMG_FNAME_SFX}
  make_and_deploy
done
