#!/usr/bin/bash

# Install the specified packages
#
# $@: Array of packages to install
# $mount_dir: Root directory of chrooted system
function install_packages() {
    arch-chroot "${mount_dir}" /usr/bin/pacman -S --noconfirm "$@"
}

# Enable the specified services
#
# $@: Array of packages to enable
# $mount_dir: Root directory of chrooted system
function enable_services() {
    arch-chroot "${mount_dir}" /usr/bin/systemctl enable "$@"
}

# Set the shell for a specified user
#
# $1: User for which to set shell
# $2: Shell executable
function set_shell() {
    arch-chroot "$mount_dir" /bin/chsh -s "$2" "$1"
}

# Set a kernel command-line option
#
# $1: Name of file to set
# $@: Options to set
function set_kernel_cmdline() {
    local name="$1"
    shift

    echo "Configuring kernel command-line '$name' ..."
    [[ -d "${mount_dir}/etc/cmdline.d" ]] || mkdir -pv "${mount_dir}/etc/cmdline.d"
    echo "$*" >"${mount_dir}/etc/cmdline.d/$name.conf"
}
