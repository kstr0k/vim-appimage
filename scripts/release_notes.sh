#!/bin/sh
set -e
vimcommiturl="https://github.com/vim/vim/commit/"
dl_counter="![Github Downloads (by Release)](https://img.shields.io/github/downloads/$GITHUB_REPOSITORY/${VERSION}/total.svg)"
version_info="**GVim: $VERSION** - Vim git commit: [$GIT_REV](${vimcommiturl}${GIT_REV}) - glibc: ${GLIBC}"
gha_build="[GitHub Actions Logfile]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)"

vimlog_md=$(git -C ../vim log --pretty='format:%H %s' $VIM_REF..$GIT_REV | sed \
    -e 's/[][_*^<`\\]/\\&/g' \
    -e "s#^\([0-9a-f]*\) patch \([0-9.a-z]*\)#* [\2]($vimcommiturl\1)#" \
    -e "s#^\([0-9a-f]*\) \(.*\)#* [\2]($vimcommiturl\1)#")

if [ -z "$vimlog_md" ]; then
  vimlog_md="_No changes unfortunately_ :worried:"
fi

cat <<EOF
## Vim AppImage Release ${VERSION}
$dl_counter<br><br>Version Information:<br>$version_info<br><br>$gha_build
<hr>

### Downloads
This release provides the following Artifacts:
* [![GVim-${VERSION}.Appimage](https://img.shields.io/github/downloads/${GITHUB_REPOSITORY}/${VERSION}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage.svg?label=downloads&logo=vim)](https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage)
* [![Vim-${VERSION}.Appimage](https://img.shields.io/github/downloads/${GITHUB_REPOSITORY}/${VERSION}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage.svg?label=downloads&logo=vim)](https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage)
<p/>

### Changelog
$vimlog_md

### What's the difference between the GVim and the Vim AppImage?

* The GVim version includes Vim's GTK3 graphical user interface and other X11 features (including clipboard support). For a **desktop** system, you'll want the GVim AppImage.
* The GVim appimage only runs on systems with the X11 libraries installed (even if you try to run it outside X11, e.g. from \`ssh\`); for a **server / headless** environment, you're better off with the Vim AppImage.

_Note_: The images are based on Ubuntu 22.04 LTS (jammy) and most likely won't work on older distributions.

### Run it
Download the AppImage, make it executable, then run it as you would run Vim (including any optional CLI arguments):
\`\`\`bash
URL='https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/'
wget -O /tmp/gvim.appimage "\$URL"/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage
chmod +x /tmp/gvim.appimage
/tmp/gvim.appimage

# alternatively, download the Vim AppImage
wget -O /tmp/vim.appimage "\$URL"/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage
chmod +x /tmp/vim.appimage
/tmp/vim.appimage
\`\`\`

You should now have a graphical vim running (if you have a graphical system and chose the GVim appimage) :smile:

If you want "terminal" Vim (but with X11 and clipboard support), download the GVim appimage, create a symbolic link with any name starting with "vim..." (or even simply \`vim\`), then run it through this symlink:
\`\`\`bash
ln -s /tmp/gvim.appimage /tmp/vim.appimage
/tmp/vim.appimage
\`\`\`

### More Information
If you need a dynamic interface to Perl, Python2, Python3.8, Ruby or Lua make sure your system provides the needed dynamic libraries (e.g. libperlX, libpython2.7 libpython3X liblua5X and librubyX) as those are **not** distributed together with the image to not make the image too large.

However, Vim will work without those libraries, but some plugins might need those additional dependencies. This means, those interpreters have to be installed in addition to Vim. Without it Vim won't be able to use those dynamic interfaces.
EOF
