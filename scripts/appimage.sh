#!/bin/bash

set -e

patch_desktop_files()
(
	# Remove duplicate keys from desktop file. This might occure while localisation
	# for the desktop file is progressing.
	cd "${SOURCE_DIR}/runtime"
	mv "${LOWERAPP}".desktop "${LOWERAPP}".desktop.orig
	awk '{x=$0; sub(/=.*$/, "", x);if(!seen[x]++){print $0}}' "${LOWERAPP}".desktop.orig > "${LOWERAPP}".desktop
	rm "${LOWERAPP}".desktop.orig

	if [ "${LOWERAPP}" = vim ]; then
		sed -i 's/^Icon=gvim/Icon=vim/' "${LOWERAPP}".desktop
	fi
	png=$(find . -xdev -name "vim48x48.png" -print -quit)
	cp "$png" "${LOWERAPP}".png
)

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

	LDAI_OUTPUT="$APPIMG_FNAME" ./linuxdeploy.appimage --appdir "$APP.AppDir" \
		-d "${SOURCE_DIR}/runtime/${LOWERAPP}.desktop" \
		-i "${SOURCE_DIR}/runtime/${LOWERAPP}.png" \
		${PLUGIN:-} \
		--output appimage
)

github_actions_deploy()
(
	[ -n "$GITHUB_ACTIONS" ] || return 0
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
cd "${SOURCE_DIR}"/src/"${LOWERAPP}"

# Prepare source files
patch_desktop_files
make install DESTDIR="${BUILD_BASE}/${APP}.AppDir" >/dev/null

# Create Appimage
make_appimage

# Perform Github Deployment
github_actions_deploy
)

compute_glibc_version() {
  find "${SOURCE_DIR}" -type f -executable -exec nm -j -D {} + 2>/dev/null | sed -ne '/@GLIBC_2[.]/{ s/.*@GLIBC_//; /^2[.][0-9][.]/d; /^2[.][0-9]$/d; p }' | uniq | sort --version-sort -r -u | head -n 1
  #/lib/x86_64-linux-gnu/libc.so.6 | sed -ne 's/.*GLIBC \(2\.[0-9][0-9]*\).*/\1/p;q'  # system version might be higher than actually required
}

script_dir=$(dirname "$(readlink -f "$0")")

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
