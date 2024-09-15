#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -o nounset -o errexit
shopt -s extglob

cat >"$HOME/.vimrc" <<VIMRC
set nocompatible

filetype on
filetype plugin on
filetype indent on

syntax on

set background=dark
colorscheme evening

set shiftwidth=2
set tabstop=4
set expandtab

set nobackup

set scrolloff=10

set nowrap

set incsearch
set ignorecase
set smartcase

set showcmd
set showmode
set showmatch
set hlsearch

set wildmenu
set wildmode=list:longest

set mouse=a

set statusline=

" Left side: full path, modified flag, read-only flag, type of file
set statusline+=\ %F\ %M\ %R\ %Y

" Divider
set statusline+=%=

" Right side: Row, Col
set statusline+=\ row:\ %l\ col:\ %c

set laststatus=2
VIMRC