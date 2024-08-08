#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -o nounset -o errexit
shopt -s extglob

export DEFAULT_DISK_SIZE="2G"
# shellcheck disable=SC2016
export MIRROR='https://geo.mirror.pkgbuild.com/$repo/os/$arch'
export CORE_PACKAGES=(
    base
    linux
    btrfs-progs dosfstools efibootmgr
    openssh
    systemd-resolvconf
    sudo
)
export CORE_SERVICES=(
    sshd
    systemd-networkd
    systemd-resolved
    systemd-timesyncd
    systemd-time-wait-sync
    pacman-init.service
)

readonly build_version="${1:-$(date +%Y-%m-%d-%H-%I-%S)}"
echo "Building version $build_version"

readonly install_dir="/install"
readonly install_scripts_dir="${install_dir}/scripts"
readonly install_files_dir="${install_dir}/files"

function cleanup() {
    echo "Cleaning up ..."

    set +o errexit
    cd "$orig_wd"

    if [[ -n "${mount_dir}" ]]; then
        umount -Rvf "$mount_dir" || true
    fi
    if [[ -n "$loop_dev" ]]; then
        losetup -d "$loop_dev"
    fi
    if [[ -n "$tmp_dir" ]] && [[ -e "$tmp_dir" ]]; then
        rm -fRv "$tmp_dir"
    fi
}
trap cleanup EXIT

# Original working directory
orig_wd="$(pwd)"
# Directory of script entry point
script_dir="$(dirname "$(realpath -- "$0")")"
# Directory where output files are placed
output_dir="$script_dir/output"
# Temporary directory
tmp_dir="$(mktemp --directory)"
# Mount point
mount_dir="${tmp_dir}/mount"
# Loop device file
loop_dev=""
# Image file name
image="image.img"

# shellcheck source=lib/bootstrap.sh
source "$script_dir/lib/bootstrap.sh"
# shellcheck source=lib/image.sh
source "$script_dir/lib/image.sh"
# shellcheck source=lib/setup.sh
source "$script_dir/lib/setup.sh"
# shellcheck source=lib/scriptlets.sh
source "$script_dir/lib/scriptlets.sh"

cd "$tmp_dir"

mkdir -pv "$mount_dir"
[[ -d "$output_dir" ]] || mkdir -pv "$output_dir"

# Build an image
# $1: Base image file
# $2: Image name
function build_image() {
    local base_img="$1"
    local img_name="$2"

    cp "$base_img" "$image"

    if [[ -n "${DISK_SIZE}" ]]; then
        echo "Resizing to $DISK_SIZE"
        truncate -s "${DISK_SIZE}" "${image}"
        sgdisk --align-end --delete 2 "${image}"
        sgdisk --align-end --move-second-header \
            --new 0:0:0 --typecode=0:8304 --change-name=0:'Arch Linux root' \
            "${image}"
    fi

    mount_image "${image}"
    if [[ -n "${DISK_SIZE}" ]]; then
        btrfs filesystem resize max "${mount_dir}"
    fi

    install_packages "${PACKAGES[@]}" "${ENV_PACKAGES[@]}"
    enable_services "${SERVICES[@]}" "${ENV_SERVICES[@]}"

    setup_env "$img_name"
    setup_img "$img_name"

    unmount_cache

    cleanup_env
    cleanup_img

    base_cleanup
    unmount_image

    local base_fn="${img_name}.${build_version}"
    local output_file="$(output_fn_env "$base_fn")"
    local manifest_file="${output_file}.manifest"

    echo "Packaging image '$output_file' from '$image' ..."
    package_env "$output_file" "$image"
    env_manifest "$output_file" "$manifest_file"

    mv_to_output "$output_file"
    mv "$manifest_file" "$output_dir"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "root is required"
    exit 1
fi

init_image
bootstrap

base_system

unmount_image

mv "$image" "root.img"

for image_file in "$script_dir/images"/image.*.sh; do
    # shellcheck disable=SC1090
    source "$image_file"

    for env_file in "$script_dir/env"/env.*.sh; do
        # shellcheck disable=SC1090
        source "$env_file"

        IMAGE_NAME="${NAME}.${ENV_NAME}"
        echo "Building ${IMAGE_NAME} ..."
        build_image "root.img" "$IMAGE_NAME"
    done
done
