#!/bin/bash
set -eu -o pipefail

if [ ! -x "$(which setup_tools.sh)" ] ; then
    echo "==> File setup_tools.sh not found."
    exit 1
else
    # Setup the parent image
    echo "==> Configuring the parent image"
    source /usr/sbin/setup_tools.sh
    echo "==> Parent tools image configured"
fi

# Change the permission of all persistent resources mounted inside $HOME.
# If you don't want to get a chowned resource, mount it somewhere else.
if [ -n "$(mount | tr -s " " | cut -d " " -f 3 | grep /home/${USERNAME})" ] ; then
    echo "Fixing mounted volumes permissions"
    declare -a RESOURCES_MOUNTED_IN_HOME
    RESOURCES_MOUNTED_IN_HOME=($(mount | tr -s " " | cut -d " " -f 3 | grep /home/${USERNAME}))
    for resource in ${RESOURCES_MOUNTED_IN_HOME[@]} ; do
        echo " -> Changing ownership of $resource"
        chown -R ${USERNAME}:${USERNAME} $resource
    done
fi

# Change the permissions of .local and .config
[ -d /home/${USERNAME}/.local ] && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.local
[ -d /home/${USERNAME}/.config ] && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config

# Configure YARP namespace
if [[ -n $(type -t yarp) ]] ; then
    echo "==> Setting YARP namespace"
    su -c "${IIT_INSTALL}/bin/yarp namespace ${YARP_NAME_SPACE:-/$USERNAME}" $USERNAME
fi
