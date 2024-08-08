#!/usr/bin/env bash

set -o nounset -o errexit
shopt -s extglob

readonly omz_dir="$HOME/.config/oh-my-zsh"

mkdir -pv "$omz_dir"
git clone "https://github.com/ohmyzsh/ohmyzsh.git" "$omz_dir"
git clone "https://github.com/zsh-users/zsh-autosuggestions.git" "${omz_dir}/custom/plugins/zsh-autosuggestions"
git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${omz_dir}/custom/plugins/zsh-syntax-highlighting"

cat >"$HOME/.zshrc" <<ZSHRC
export PATH=\$HOME/bin:\$HOME/.local/bin:/usr/local/bin:\$PATH
export ZSH=\$HOME/.config/oh-my-zsh

ZSH_THEME="clean"

CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

zstyle ':omz:update' mode disabled
# zstyle ':omz:update' frequency 13

HIST_STAMPS="yyyy-mm-dd"

plugins=(
    archlinux
    git
    sudo
    systemd
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source \$ZSH/oh-my-zsh.sh

export EDITOR="vim"
export VISUAL="\$EDITOR"
export PAGER="less"
ZSHRC
