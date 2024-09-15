#!/usr/bin/bash

# Attach and mount a previously initialized image file
#
# $1: Path of image file
# $tmp_dir: Path to build tmp directory
# $install_scripts_dir: Path to directory where install scripts are placed
# $install_files_dir: Path to directory where install files are placed
#
# Sets `loop_dev` variable to loop device path.
function mount_image() {
    local image="$1"

    loop_dev="$(losetup --find --partscan --show "${image}")"

    wait_for_device "$loop_dev" "2"

    mount_dir="${tmp_dir}/mount"

    mount -o compress-force=zstd "${loop_dev}p2" "${mount_dir}"
    mount "${loop_dev}p1" "${mount_dir}/boot"

    cache_mount_dir="${mount_dir}/var/cache/pacman/pkg"
    mount --bind "/var/cache/pacman/pkg" "$cache_mount_dir"

    [[ -d "${mount_dir}${install_scripts_dir}" ]] || mkdir -pv "${mount_dir}${install_scripts_dir}"
    [[ -d "${mount_dir}${install_files_dir}" ]] || mkdir -pv "${mount_dir}${install_files_dir}"
}

# Wait until a loop device becomes available
#
# $1: Path to loop device file
# $2: Number of partition for which to wait
function wait_for_device() {
    local device="$1"
    local partition="$2"

    udevadm settle
    blockdev --flushbufs --rereadpt "${device}"

    local partdevice="${device}p${partition}"
    until [[ -e "${partdevice}" ]]; do
        echo "Waiting for ${partdevice} ..."
        sleep 1
    done
}

# Unmount cache bind mounts
#
# $cache_mount_dir: Mount point to unmount
function unmount_cache() {
    if [[ -n "${cache_mount_dir+x}" ]]; then
        echo "Unmounting cache mount ..."
        umount -Rv "$cache_mount_dir" || true
    fi
}

# Unmount and detach the currently mounted image
#
# $mount_dir: Mount point to unmount
# $loop_dev: Loop device to detach
function unmount_image() {
    umount -Rv "$mount_dir"
    losetup -d "$loop_dev"
    loop_dev=""
}

# Move the specified file to the output directory and compute hashes
#
# $1: Name of file to move.
function mv_to_output() {
    local source_file="$1"
    md5sum -b "${source_file}" >"${source_file}.md5"
    sha256sum -b "${source_file}" >"${source_file}.sha256"
    sha512sum -b "${source_file}" >"${source_file}.sha512"
    b2sum -b "${source_file}" >"${source_file}.b2"
    mv "${source_file}"{,.md5,.sha256,.sha512,.b2} "$output_dir"
}
