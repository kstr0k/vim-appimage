#!/bin/sh
set -e
vimcommiturl="https://github.com/vim/vim/commit/"
dl_counter="![Github Downloads (by Release)](https://img.shields.io/github/downloads/$GITHUB_REPOSITORY/${kstr0k_tag}/total.svg)"
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
## Custom vim-appimage release ${VERSION}
$dl_counter<br><br>Version Information:<br>$version_info<br><br>$gha_build
<hr>

### Downloads
This release provides the following Artifacts:
* [![GVim-${VERSION}.Appimage](https://img.shields.io/github/downloads/${GITHUB_REPOSITORY}/${kstr0k_tag}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage.svg?label=downloads&logo=vim)](https://github.com/${GITHUB_REPOSITORY}/releases/download/${kstr0k_tag}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage)
* [![Vim-${VERSION}.Appimage](https://img.shields.io/github/downloads/${GITHUB_REPOSITORY}/${kstr0k_tag}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage.svg?label=downloads&logo=vim)](https://github.com/${GITHUB_REPOSITORY}/releases/download/${kstr0k_tag}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage)
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

Finally, it's possible to *extract* the AppImage to a folder ("AppDir") and run vim / gvim directly from there, using the \`AppRun.extracted\` script included in the AppImage. For frequent usage, this incurs less overhead and brings up vim faster than the AppImage (which internally auto-mounts its own "AppDir" on every run). Plus (compared to using distro packages) you still get the latest Vim. For example, for the GVim appimage:
\`\`\`bash
cd /tmp; ./gvim.appimage --appimage-extract
mv squashfs-root ~/gvim.AppDir
ln -s ~/gvim.AppDir/AppRun.extracted ~/bin/gvim
ln -s ~/gvim.AppDir/AppRun.extracted ~/bin/vim
\`\`\`

### Optional libraries

To use Vim's dynamic interface to Perl, Python2, Python3.10, Ruby 3, or Lua, make sure your system provides the needed dynamic libraries (packages like \`libperl* libpython2* libpython3* liblua5* libruby*\` from your distribution) as those are **not** distributed with the images (to keep their size reasonable among other reasons).

Vim will run without those libraries / languages, but plugins that require them obviosuly won't. You can install those interpreters later on your system if you decide you need them.
EOF
