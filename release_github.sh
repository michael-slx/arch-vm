#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -o nounset -o errexit
shopt -s extglob

readonly script_dir="$(dirname "$(realpath -- "$0")")"
readonly RELEASE_VERSION="${1}"
if [[ -z "$RELEASE_VERSION" ]]; then
    echo "Missing release version"
    exit 1
fi

release_files=("$script_dir/output"/*.box!(.manifest))
echo "Publishing files:"
IFS=$'\n'
echo "${release_files[*]}"
unset IFS
echo ""

echo "Creating release $RELEASE_VERSION"
body="Release $RELEASE_VERSION"
gh release create --draft "$RELEASE_VERSION" --title "$RELEASE_VERSION" --notes "$body"

echo "Uploading release files"
gh release upload "$RELEASE_VERSION" "${release_files[@]}"

echo "Publishing release $RELEASE_VERSION"
gh release edit "$RELEASE_VERSION" --draft=false
