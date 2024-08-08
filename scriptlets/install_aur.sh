#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -o nounset -o errexit
shopt -s extglob

readonly BASE_DIR="$HOME/.cache/aur"
readonly orig_wd="$(pwd)"

function cleanup() {
    echo "Cleaning up ..."

    cd "$orig_wd"
}
trap cleanup EXIT

[[ -d "$BASE_DIR" ]] || mkdir -pv "$BASE_DIR"

for package in "$@"; do
    build_dir="$BASE_DIR/$package"
    url="https://aur.archlinux.org/${package}.git"
    echo "Building $package in $build_dir"

    if [[ ! -d "$build_dir" ]]; then
        echo "Cloning '$package' AUR package ..."
        git clone "$url" "$build_dir"
        cd "$build_dir"
    else
        echo "Pulling '$package' AUR package ..."
        cd "$build_dir"
        git pull origin
    fi

    makepkg -si --needed --noconfirm
done
