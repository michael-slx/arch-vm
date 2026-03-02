FROM archlinux/archlinux
RUN pacman -Syuu --needed --noconfirm \
        base-devel \
        coreutils jq \
        gptfdisk btrfs-progs dosfstools qemu-img \
        arch-install-scripts \
        github-cli
RUN <<SHELL
git clone https://aur.archlinux.org/vagrant.git ~/vagrant
cd ~/vagrant
makepkg -si --noconfirm
cd ~
rm -fR ~/vagrant
SHELL
