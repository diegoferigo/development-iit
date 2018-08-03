#!/bin/bash
set -e

# Setup the parent image
source /usr/sbin/setup_tools.sh

# Setup the custom bashrc
echo "Including additional bashrc configurations"
# -dev
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

# Configure git
if [[ ! -z ${GIT_USER_NAME:+x} && ! -z ${GIT_USER_EMAIL:+x} ]] ; then
	echo "Setting up git ..."
	su -c "git config --global user.name ${GIT_USER_NAME}" $USERNAME
	su -c "git config --global user.email ${GIT_USER_EMAIL}" $USERNAME
	su -c "git config --global color.pager true" $USERNAME
	su -c "git config --global color.ui auto" $USERNAME
	su -c "git config --global push.default upstream" $USERNAME
	if [[ "${GIT_USE_GPG}" = "1" && -n "${GIT_GPG_KEY}" ]] ; then
    su -c "export GPG_TTY=$(tty)" $USERNAME
		su -c "git config --global commit.gpgsign true" $USERNAME
		su -c "git config --global gpg.program gpg2" $USERNAME
		su -c "git config --global user.signingkey ${GIT_GPG_KEY}" $USERNAME
	fi
	echo "... Done"
fi

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
	su -c 'eval "${IIT_INSTALL}/bin/yarp namespace ${YARP_NAME_SPACE}"' $USERNAME
fi

# Setup ROS environment
if [ -e /opt/ros/$ROS_DISTRO/setup.bash ] ; then
    source "/opt/ros/$ROS_DISTRO/setup.bash"
fi
