#!/usr/bin/bash

function exec_scriptlet() {
    local scriptlet_name="$1"
    shift
    local args=("$@")

    local scriptlet_file="${script_dir}/scriptlets/${scriptlet_name}"

    cp -v "$scriptlet_file" "${mount_dir}${install_scripts_dir}/${scriptlet_name}"

    echo "Executing ${scriptlet_name} with args ${args[*]}"
    arch-chroot "${mount_dir}" /bin/bash "${install_scripts_dir}/${scriptlet_name}" "${args[@]}"
}

function exec_user_scriptlet() {
    local scriptlet_name="$1"
    local username="$2"
    shift 2

    local scriptlet_file="${script_dir}/scriptlets/${scriptlet_name}"

    cp -v "$scriptlet_file" "${mount_dir}${install_scripts_dir}/${scriptlet_name}"
    arch-chroot "${mount_dir}" /bin/chown -v "$username:$username" "${install_scripts_dir}/${scriptlet_name}"
    arch-chroot "${mount_dir}" /bin/chmod -v 0750 "${install_scripts_dir}/${scriptlet_name}"
    arch-chroot "${mount_dir}" /bin/su - "$username" <<CMD
"${install_scripts_dir}/${scriptlet_name}" $@
CMD
}
