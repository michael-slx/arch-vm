#!/usr/bin/env bash
set -o nounset -o errexit
shopt -s extglob

readonly username="$1"
readonly password="$username"

echo "Creating user $username"
useradd -m -U "${username}"
echo -e "${password}\n${password}" | passwd "${username}"

cat <<SUDOERS >"/etc/sudoers.d/${username}"
Defaults:${username} !requiretty
${username} ALL=(ALL) NOPASSWD: ALL
SUDOERS
chmod 440 "/etc/sudoers.d/${username}"

install --directory --owner="$username" --group="$username" --mode=0700 "/home/$username/.ssh"
curl --output "/home/$username/.ssh/authorized_keys" --location https://github.com/hashicorp/vagrant/raw/main/keys/vagrant.pub

# WARNING: Please only update the hash if you are 100% sure it was intentionally updated by upstream.
sha256sum -c <<<"55009a554ba2d409565018498f1ad5946854bf90fa8d13fd3fdc2faa102c1122 "/home/$username/.ssh/authorized_keys""

chown "$username":"$username" /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
