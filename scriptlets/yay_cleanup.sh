#!/usr/bin/env bash

set -o nounset -o errexit
shopt -s extglob

echo "Cleaning yay caches"
yes | yay -Sccc
