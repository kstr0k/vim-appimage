#!/bin/bash

set -e

unsorted_uniq() {
  awk '{x=$0; sub(/=.*$/, "", x);if(!seen[x]++){print $0}}'
}

patch_desktop_files()
(
	# Remove duplicate keys from desktop file. This might occure while localisation
	# for the desktop file is progressing.
	cd "${VIM_DIR}/runtime"
	mv "${LOWERAPP}".desktop "${LOWERAPP}".desktop.orig
	unsorted_uniq <"${LOWERAPP}.desktop.orig" >"${LOWERAPP}".desktop
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

	export UPDATE_INFORMATION="gh-releases-zsync|vim|vim-appimage|latest|$APP-*x86_64.AppImage.zsync"
	export OUTPUT="${APP}-${VERSION}.glibc${GLIBC}-${ARCH}.AppImage"

	./linuxdeploy.appimage --appdir "$APP.AppDir" \
		-d "${VIM_DIR}/runtime/${LOWERAPP}.desktop" \
		-i "${VIM_DIR}/runtime/${LOWERAPP}.png" \
		${PLUGIN:-} \
		--output appimage
)

github_actions_deploy()
(
	cd -P "${BUILD_BASE}"
	if [ -n "$GITHUB_ACTIONS" ]; then
		# Copy artifacts to $GITHUB_WORKSPACE
		TARGET_NAME=$(find "$PWD/" -type f -name "$APP-*.AppImage" -printf '%f\n')
		printf '%s\n' "Copy $BUILD_BASE/$TARGET_NAME -> $GITHUB_WORKSPACE"
		cp "$TARGET_NAME" "$GITHUB_WORKSPACE"
		cp "$TARGET_NAME.zsync" "$GITHUB_WORKSPACE"

		# Github Release Notes
		(cd "$script_dir"; . release_notes.sh > "$GITHUB_WORKSPACE/release.body")
	fi
)

script_dir=$(dirname "$(readlink -f "$0")")

APP=${1:-GVim}

if [ -n "$GITHUB_ACTIONS" ]; then
    echo "GitHub Actions detected"
    BUILD_BASE=$HOME
else
    BUILD_BASE="$script_dir/../build"
    mkdir -p "$BUILD_BASE"
fi

pushd vim
GIT_REV="$(git rev-parse --short HEAD)"
# should use tag if available, else use 7-hexdigit hash
VERSION="$(git describe --tags --abbrev=0 || git describe --always)"

VIM_DIR="$(git rev-parse --show-toplevel)"
ARCH=$(arch)
LOWERAPP=${APP,,}
popd

# uses the shadowdir from build_vim.sh
pushd vim/src/"$LOWERAPP"

GLIBC=$(find "${VIM_DIR}" -type f -executable -exec nm -j -D {} + 2>/dev/null | sed -ne '/@GLIBC_2[.]/{ s/.*@GLIBC_//; /^2[.][0-9][.]/d; /^2[.][0-9]$/d; p }' | uniq | sort --version-sort -r -u | head -n 1)
#GLIBC=$(/lib/x86_64-linux-gnu/libc.so.6 | sed -ne 's/.*GLIBC \(2\.[0-9][0-9]*\).*/\1/p;q')  # system version might be higher than actually required

# Prepare some source files
patch_desktop_files

make install DESTDIR="${BUILD_BASE}/${APP}.AppDir" >/dev/null

# Create Appimage
make_appimage

# Perform Github Deployment
github_actions_deploy

popd
