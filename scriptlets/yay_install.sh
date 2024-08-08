#!/usr/bin/env bash

set -o nounset -o errexit
shopt -s extglob

yay -Sy --noconfirm "$@"
