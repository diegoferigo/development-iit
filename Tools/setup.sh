#!/bin/bash
set -eu -o pipefail 

if [ ! -x "$(which setup_devenv.sh)" ] ; then
    echo "==> File setup_devenv.sh not found."
    exit 1
else
    # Setup the parent image
    echo "==> Configuring the parent image"
    source /usr/sbin/setup_devenv.sh
    echo "==> Parent devenv image configured"
fi

# Bootstrap dotfiles
if [[ $(id -u ${USERNAME:-root}) -gt 0 && -f /usr/local/dotfiles/bootstrap ]] ; then
    echo "==> Setting up dotfiles for the runtime user"
    [[ -d /home/${USERNAME}/.local ]] && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.local
    [[ -d /home/${USERNAME}/.local/share ]] && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.local/share
    [[ -d /home/${USERNAME}/.config ]] && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.config
    su -c "mkdir -p /home/${USERNAME}/.local" $USERNAME
    su -c "mkdir -p /home/${USERNAME}/.config/fish" $USERNAME
    su -c "bash -i /usr/local/dotfiles/bootstrap" $USERNAME || echo "Failed to initialize dotfiles"
fi
