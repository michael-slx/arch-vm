#!/usr/bin/bash

function init_image() {
    truncate -s "${DEFAULT_DISK_SIZE}" "${image}"
    sgdisk \
        --align-end \
        --clear \
        --new 0:0:+256M --typecode=0:ef00 --change-name=0:'EFI' \
        --new 0:0:0 --typecode=0:8304 --change-name=0:'ROOT' \
        "${image}"

    loop_dev="$(losetup --find --partscan --show "${image}")"

    wait_for_device "$loop_dev" "2"

    mkfs.vfat -F32 -n "EFI" "${loop_dev}p1"
    mkfs.btrfs -L "ROOT" "${loop_dev}p2"

    mount -o compress-force=zstd "${loop_dev}p2" "${mount_dir}"
    mount --mkdir "${loop_dev}p1" "${mount_dir}/boot"
}

function bootstrap() {
    cat  >pacman.conf <<EOF
[options]
Architecture = auto

[core]
Include = mirrorlist

[extra]
Include = mirrorlist
EOF
    echo "Server = ${MIRROR}" >mirrorlist

    pacstrap -C pacman.conf -c -M "${mount_dir}" "${CORE_PACKAGES[@]}"
    arch-chroot "${mount_dir}" /usr/bin/pacman-key --init
    [[ -d "${mount_dir}/etc/pacman.d" ]] || mkdir -pv "${mount_dir}/etc/pacman.d"
    cp -v mirrorlist "${mount_dir}/etc/pacman.d/"

    cat <<EOF >"${mount_dir}/etc/systemd/system/pacman-init.service"
[Unit]
Description=Initialize Pacman keyring
Before=sshd.service cloud-final.service archlinux-keyring-wkd-sync.service
After=time-sync.target
ConditionFirstBoot=yes

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/pacman-key --init
ExecStart=/usr/bin/pacman-key --populate

[Install]
WantedBy=multi-user.target
EOF

    enable_services "${CORE_SERVICES[@]}"
}

function base_system() {
    arch-chroot "${mount_dir}" /usr/bin/btrfs subvolume create /swap
    chattr +C "${mount_dir}/swap"
    chmod 0700 "${mount_dir}/swap"
    arch-chroot "${mount_dir}" /usr/bin/btrfs filesystem mkswapfile --size 512m --uuid clear /swap/swapfile
    echo -e "/swap/swapfile none swap defaults 0 0" >>"${mount_dir}/etc/fstab"

    arch-chroot "${mount_dir}" /usr/bin/systemd-firstboot --locale=C.UTF-8 --timezone=UTC --hostname=archlinux --keymap=us
    ln -sf /run/systemd/resolve/stub-resolv.conf "${mount_dir}/etc/resolv.conf"
}

function base_cleanup() {
    [[ -e "${mount_dir}/etc/machine-id" ]] && rm "${mount_dir}/etc/machine-id"
    [[ -e "${mount_dir}/etc/pacman.d/gnupg" ]] && rm -Rf "${mount_dir}/etc/pacman.d/gnupg"
    [[ -e "${mount_dir}${install_dir}" ]] && rm -Rf "${mount_dir}${install_dir}"

    sync -f "${mount_dir}/etc/os-release"
    fstrim --verbose "${mount_dir}"
    fstrim --verbose "${mount_dir}/boot"
}
