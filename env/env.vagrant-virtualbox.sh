#!/usr/bin/bash

export ENV_NAME="vagrant-virtualbox"
export ENV_PACKAGES=(
    "systemd-ukify"
    "virtualbox-guest-utils-nox"
)
export USER="vagrant"
export ENV_SERVICES=("vboxservice")
export VAGRANT_PROVIDER="virtualbox"
export VAGRANT_ARCH="amd64"

function setup_env() {
    echo "Setting up '$ENV_NAME' image ..."

    configure_network

    set_kernel_cmdline "root" "root=LABEL=ROOT rw"
    configure_mkinitcpio

    exec_scriptlet "create_vagrant_user.sh" "$USER"
}

function configure_network() {
    echo "Configuring network ..."
    cat >"${mount_dir}/etc/systemd/network/50-dhcp.network" <<NETWORK
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
NETWORK
}

function configure_mkinitcpio() {
    echo "Configuring mkinitcpio ..."

    [[ -d "${mount_dir}/boot/EFI/BOOT" ]] || mkdir -pv "${mount_dir}/boot/EFI/BOOT"
    cat >"${mount_dir}/etc/mkinitcpio.conf" <<MKINITCPIO
MODULES=(btrfs ahci)
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect modconf sd-vconsole)
COMPRESSION="cat"
MKINITCPIO
    cat >"${mount_dir}/etc/mkinitcpio.d/linux.preset" <<MKINITCPIOPRESET
# mkinitcpio preset file for the 'linux' package

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_uki="/boot/EFI/BOOT/BOOTX64.EFI"
default_options=""
MKINITCPIOPRESET

    rm -fv "$mount_dir/boot"/initramfs-*.img
    arch-chroot "$mount_dir" /bin/mkinitcpio -P
}

function cleanup_env() {
    echo "Cleaning up '$ENV_NAME' name ..."
}

function output_fn_env() {
    local target_filename="$1"
    echo "${target_filename}.box"
}

function package_env() {
    local target_filename="$1"
    local img_filename="$2"

    local vmdk_filename="vbox.vmdk"

    local mac_address="080027$(openssl rand -hex 3 | tr '[:lower:]' '[:upper:]')"
    cat >Vagrantfile <<VAGRANTFILE
Vagrant.configure("2") do |config|
  config.vm.base_mac = "${mac_address}"
end
VAGRANTFILE
    echo "{\"architecture\":\"$VAGRANT_ARCH\",\"provider\":\"$VAGRANT_PROVIDER\"}" >metadata.json
    qemu-img convert -f raw -O vmdk "$img_filename" "$vmdk_filename"
    rm "$img_filename"

    cp "${script_dir}/box.ovf" .
    sed -e "s/MACHINE_UUID/$(uuidgen)/" \
        -e "s/DISK_UUID/$(uuidgen)/" \
        -e "s/DISK_CAPACITY/$(qemu-img info --output=json "$vmdk_filename" | jq '."virtual-size"')/" \
        -e "s/VMDK_FILE_NAME/${vmdk_filename}/" \
        -e "s/UNIX/$(date +%s)/" \
        -e "s/MAC_ADDRESS/${mac_address}/" \
        -i box.ovf

    tar -czf "${target_filename}" Vagrantfile metadata.json $vmdk_filename box.ovf
    rm Vagrantfile metadata.json vbox.vmdk box.ovf
}

function env_manifest() {
    local target_filename="$1"
    local manifest_file="$2"

    local sha512_dgst="$(sha512sum <"$target_filename" | awk '{print $1}')"

    cat >"$manifest_file" <<MANIFEST
FILE="$target_filename"
BOX="$NAME"
HASH_SHA512="$sha512_dgst"
PROVIDER="$VAGRANT_PROVIDER"
ARCH="$VAGRANT_ARCH"
MANIFEST
}
