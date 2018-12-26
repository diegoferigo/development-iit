#!/bin/bash
set -eu -o pipefail

# Setup the parent image
source /usr/sbin/setup_tools.sh

# Setup the custom bashrc
echo "==> Including additional bashrc configurations"
cp /usr/etc/skel/bashrc-dev /home/$USERNAME/.bashrc-dev
chown ${USERNAME}:${USERNAME} /home/$USERNAME/.bashrc-dev
echo "source /home/$USERNAME/.bashrc-dev" >> /home/${USERNAME}/.bashrc
echo "source /home/$USERNAME/.bashrc-dev" >> /root/.bashrc

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

# Fix permissions of the IIT directory
CHOWN_SOURCES=${CHOWN_SOURCES:-0}
if [[ ${CHOWN_SOURCES} -eq 1 && -d ${IIT_DIR} ]] ; then
    # Do this in background since it might be a slow operation if the folder is big
	chown $USERNAME:$USERNAME ${IIT_DIR}
	chown -R $USERNAME:$USERNAME ${IIT_DIR}/sources &
	chown -R $USERNAME:$USERNAME ${IIT_DIR}/local &
fi

# Configure YARP namespace
if [ -n "${YARP_NAME_SPACE}" ] ; then
    echo "==> Setting Yarp namespace"
	su -c 'eval "${IIT_INSTALL}/bin/yarp namespace ${YARP_NAME_SPACE}"' $USERNAME
fi
