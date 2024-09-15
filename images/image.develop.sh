#!/usr/bin/env bash

export NAME="arch-develop"
export DISK_SIZE="64G"
export PACKAGES=(
    base-devel
    vim nano
    wget curl
    git subversion mercurial
    man-db man-pages texinfo
    zsh bash bash-completion
)
export MAKEPKG=(
    yay
)
export SERVICES=()
export AUR_PACKAGES=(
    auracle-git
    aurutils
    bauerbill
    pacaur
#   paru           # Disabled for now - Compile error
    pikaur
    repoctl
    trizen
    yaah
    yay
)

function setup_img() {
    echo "Setting up '$NAME' image ..."

    exec_scriptlet "configure_pacman.sh"

    mount_user_cache

    exec_user_scriptlet "install_aur.sh" "$USER" "${MAKEPKG[@]}"
    exec_user_scriptlet "yay_install.sh" "$USER" "$@" "${AUR_PACKAGES[@]}"

    exec_user_scriptlet "configure_zsh.sh" "$USER"
    set_shell "$USER" "/usr/bin/zsh"
    exec_user_scriptlet "configure_vim.sh" "$USER"

}

function mount_user_cache() {
    echo "Mounting user '$USER' cache ..."
    [[ -d "/var/cache/user/$USER" ]] || mkdir -pv "/var/cache/user/$USER"
    [[ -d "$mount_dir/home/$USER/.cache" ]] || mkdir -pv "$mount_dir/home/$USER/.cache"
    mount --bind -v "/var/cache/user/$USER" "$mount_dir/home/$USER/.cache"
    arch-chroot "$mount_dir" /bin/chown "$USER:$USER" "/home/$USER/.cache"
    arch-chroot "$mount_dir" /bin/chmod 0750 "/home/$USER/.cache"
}

function cleanup_img() {
    echo "Cleaning up '$NAME' name ..."

    unmount_user_cache
    exec_user_scriptlet "yay_cleanup.sh" "$USER"
}

function unmount_user_cache() {
    echo "Unmounting cache of user '$USER' ..."
    umount -v "$mount_dir/home/$USER/.cache" || true
    arch-chroot "$mount_dir" /bin/chown -Rv "$USER:$USER" "/home/$USER/.cache"
    arch-chroot "$mount_dir" /bin/chmod -Rv 0750 "/home/$USER/.cache"
}
