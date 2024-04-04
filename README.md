[![Build Status](https://github.com/kstr0k/vim-appimage/workflows/Release%20AppImage/badge.svg)](https://github.com/kstr0k/vim-appimage/actions?query=workflow%3A%22Release+AppImage%22)

# Vim AppImage Repository

**Note**: this is a *fork* of the [official vim/vim-appimage](https://github.com/vim/vim-appimage/) repo. It uses a newer Ubuntu base image (22.04 "jammy" &mdash; avoiding some warnings when running GVim on current Linux distros).

This project builds 64bit Vim &amp; Gvim AppImage releases from the latest Vim snapshots.  AppImage (https://appimage.org/) is a cross-distribution packaging format that runs from a single file on "any" system (in practice, "too different" distros might not be compatible).

[Download](releases) and execute the most recent GVim AppImage to run GVim (previous releases in this repo go back to Vim `v9.1.0228`). It most likely won't work on old distributions &mdash; you could try the [vim/vim-appimage](https://github.com/vim/vim-appimage/) repo, which currently builds on Ubuntu 20.04, and used to build on 18.04 up to [release `v9.0.1413`](https://github.com/vim/vim-appimage/releases/tag/v9.0.1413).

See the release notes for running
* terminal Vim from the GVim appimage
* the separate Vim AppImage built with no X11 dependencies (but no X11 support)
* locally-extracted AppImages

The vim / gvim AppImage's are built with Vim interfaces for Perl, Python3, Ruby
and Lua. See the release notes for usage and details.

See: https://github.com/vim/vim
