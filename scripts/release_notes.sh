#!/bin/sh
set -e
vimcommiturl="https://github.com/vim/vim/commit/"
dl_counter="![Github Downloads (by Release)](https://img.shields.io/github/downloads/$GITHUB_REPOSITORY/${release_tag}/total.svg)"
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
## vim-appimage release ${release_tag}
$dl_counter<br><br>Version Information:<br>$version_info<br><br>$gha_build
<hr>

### Downloads
This release provides the following Artifacts:
* [![GVim-${VERSION}.Appimage](https://img.shields.io/github/downloads/${GITHUB_REPOSITORY}/${release_tag}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage.svg?label=downloads&logo=vim)](https://github.com/${GITHUB_REPOSITORY}/releases/download/${release_tag}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage)
* [![Vim-${VERSION}.Appimage](https://img.shields.io/github/downloads/${GITHUB_REPOSITORY}/${release_tag}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage.svg?label=downloads&logo=vim)](https://github.com/${GITHUB_REPOSITORY}/releases/download/${release_tag}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage)
<p/>

### Changelog
$vimlog_md

### What is the Difference between the GVim and the Vim Appimage?
The difference between the GVim and Vim Appimage is, that the GVim version includes a graphical User Interface (GTK3) and other X11 features like clipboard handling. That means, for proper clipboard support, you'll **need** the GVim Appimage, but you can only run this on a system that has the X11 libraries installed. <p/>

For a Server or headless environment, you are probably be better with the Vim version.<p/> _Note_: The image is based on Ubuntu 20.04 LTS focal. It most likely won't work on older distributions.

### Run it
Download the AppImage, make it executable then you can just run it:
\`\`\`bash
wget -O /tmp/gvim.appimage https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/GVim-${VERSION}.glibc${GLIBC}-x86_64.AppImage
chmod +x /tmp/gvim.appimage
/tmp/gvim.appimage
# alternatively, download the Vim Appimage
wget -O /tmp/vim.appimage https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/Vim-${VERSION}.glibc${GLIBC}-x86_64.AppImage
chmod +x /tmp/vim.appimage
/tmp/vim.appimage
\`\`\`

That's all, you should have a graphical vim now running (if you have a graphical system running) :smile: 

If you want a terminal Vim (with X11 and clipboard feature enabled), just create a symbolic link with a name starting with "vim". Like:
\`\`\`bash
ln -s /tmp/gvim.appimage /tmp/vim.appimage
\`\`\`

Then execute \`vim.appimage\` to get a terminal Vim.

### More Information
If you need a dynamic interface to Perl, Python2, Python3.8, Ruby or Lua make sure your system provides the needed dynamic libraries (e.g. libperlX, libpython2.7 libpython3X liblua5X and librubyX) as those are **not** distributed together with the image to not make the image too large.

However, Vim will work without those libraries, but some plugins might need those additional dependencies. This means, those interpreters have to be installed in addition to Vim. Without it Vim won't be able to use those dynamic interfaces.
EOF
