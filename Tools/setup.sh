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
    mkdir -p /home/${USERNAME}/.local && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.local
    mkdir -p /home/${USERNAME}/.config/fish && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.config
    su -c "bash /usr/local/dotfiles/bootstrap" $USERNAME || echo "Failed to initialize dotfiles"
fi
