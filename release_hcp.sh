#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -o nounset -o errexit
shopt -s extglob

readonly script_dir="$(dirname "$(realpath -- "$0")")"
if [[ -z "${1+x}" ]]; then
    echo "Missing release version"
    exit 1
fi
readonly RELEASE_VERSION="${1}"

if [[ -z "${2+x}" ]]; then
    echo "Missing HCP organization name"
    exit 2
fi
readonly VAGRANT_ORG="${2}"
echo "HCP Organization: $VAGRANT_ORG"

manifest_files=("$script_dir/output"/*.manifest)
echo "Publishing manifests:"
IFS=$'\n'
echo "${manifest_files[*]}"
unset IFS
echo ""

for manifest_file in "${manifest_files[@]}"; do
    # shellcheck disable=SC1090
    source "$manifest_file"
    echo "Publishing ${BOX} for ${ARCH} ${PROVIDER} ..."

    release_description="Release $RELEASE_VERSION"
    full_file_path="${script_dir}/output/${FILE}"

    vagrant cloud publish \
        --architecture "${ARCH}" \
        --default-architecture \
        --version-description "${release_description}" \
        --checksum "${HASH_SHA512}" \
        --checksum-type "sha512" \
        --release \
        --force \
        "${VAGRANT_ORG}/${BOX}" \
        "${RELEASE_VERSION}" \
        "${PROVIDER}" \
        "${full_file_path}"
done
