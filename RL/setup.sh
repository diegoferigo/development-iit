#!/bin/bash
set -eu -o pipefail

if [ -x "$(which setup_development.sh)" ] ; then
    # Setup the parent image
    echo "==> Configuring the parent image"
    source $(which setup_development.sh)
    echo "==> Parent development image configured"
    
    # Setup git for the runtime user
    su -c "git config --global remote-hg.ignore-name '~|pre|pendulum'" $USERNAME
    
    # Fix permissions of the IIT directory
    if [[ ${CHOWN_SOURCES:-0} -eq 1 && -d ${RL_DIR} ]] ; then
        # Do this in background since it might be a slow operation if the folder is big
        chown $USERNAME:$USERNAME ${RL_DIR}
        chown -R $USERNAME:$USERNAME ${RL_DIR}/sources &
        chown -R $USERNAME:$USERNAME ${RL_DIR}/local &
    fi
fi
