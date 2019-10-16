#!/bin/bash
set -eu -o pipefail

if [ -x "$(which setup_development.sh)" ] ; then
    # Setup the parent image
    echo "==> Configuring the parent image"
    source $(which setup_development.sh)
    echo "==> Parent development image configured"
    
    # Setup git for the runtime user
    su -c "git config --global remote-hg.ignore-name '~|pre|pendulum'" $USERNAME
fi

# =================
# SETUP ATOM / JUNO
# =================

ATOM_FOLDER="/home/$USERNAME/.atom"

# Create the .atom folder if it does not exist
if [ ! -d ${ATOM_FOLDER} ] ; then
    su -c "mkdir -p ${ATOM_FOLDER}" $USERNAME
fi

# Check if it is empty
set +e +o pipefail
find ${ATOM_FOLDER} -mindepth 1 | read

# If empty, copy the default packages
if [ $? -eq 1 ] ; then
    echo "==> Copying atom folder with default packages in the user home"
    cp -r /opt/dotatom/* /home/$USERNAME/.atom/
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.atom
fi

set -eu -o pipefail
