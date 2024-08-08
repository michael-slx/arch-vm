#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -o nounset -o errexit
shopt -s extglob

readonly PACMANCONF="/etc/pacman.conf"

echo "Configuring pacman: $PACMANCONF"

cat >>"$PACMANCONF" <<CONF
[options]
Color
ParallelDownloads = 5
CheckSpace
VerbosePkgLists
NoExtract = etc/pacman.conf etc/pacman.d/mirrorlist
CONF

sed \
    -e 's/^NoProgressBar/#NoProgressBar/' \
    -i "$PACMANCONF"
