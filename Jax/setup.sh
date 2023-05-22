#!/bin/bash
set -e

# These variables can be overridden by docker environment variables
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
USERNAME=${USER_NAME:-docker}
USER_HOME=${USER_HOME:-/home/$USER_NAME}

create_user() {
    # If the home folder exists, set a flag.
    # Creating the user during container initialization often is anticipated
    # by the mount of a docker volume. In this case the home directory is already
    # present in the file system and adduser skips by default the copy of the
    # configuration files.
    HOME_FOLDER_EXISTS=0
    if [ -d $USER_HOME ] ; then HOME_FOLDER_EXISTS=1 ; fi

    # Create a group with USER_GID
    if ! getent group ${USERNAME} >/dev/null; then
        groupadd -f -g ${USER_GID} ${USERNAME} >/dev/null
    fi

    # Create a user with USER_UID
    if ! getent passwd ${USERNAME} >/dev/null; then
        adduser --quiet \
                --disabled-login \
                --home ${USER_HOME} \
                --uid ${USER_UID} \
                --gid ${USER_GID} \
                --gecos 'Workspace' \
                ${USERNAME}
    fi

    # The home must belong to the user
    chown ${USER_UID}:${USER_GID} ${USER_HOME}

    # If configuration files have not been copied, do it manually
    if [ ${HOME_FOLDER_EXISTS} -ne 0 ] ; then

        for file in .bashrc .bash_logout .profile ; do
            if [[ ! -f ${USER_HOME}/${file} ]] ; then
                install -m 644 -g ${USERNAME} -o ${USERNAME} /etc/skel/${file} ${USER_HOME}
            fi
        done
    fi
}

# Create the user if it was not disabled and if run -u is not used
if [[ ${CREATE_RUNTIME_USER:-1} -eq 1 && $(id -u) -eq 0 ]] ; then
    echo "  --> Creating runtime user" "'""${USERNAME}:${USERNAME}""'"
    create_user

    echo "  --> Enabling password-less execution"
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} &&\
    chmod 0440 /etc/sudoers.d/${USERNAME}

    # Add the user to video group for HW acceleration (Intel GPUs)
    usermod -aG video ${USERNAME}

    # Assign the user to the runtimeusers group
    gpasswd -a ${USERNAME} runtimeusers >/dev/null

    # Fix ownership error of existing git repositories
    su -c "git config --global --add safe.directory '*'" ${USERNAME}
fi

if [[ -d ${USER_HOME} ]] ; then
    # When volumes are mounted inside user's $HOME, docker creates parent folders owned by root:root.
    # Since we may need to access in r/w these folders, we first change the group owner to runtimeusers
    # and then ensure that group permissions match the owner permissions.
    find ${USER_HOME} -group root -type d -perm /u+w -not -perm -g+w -exec chgrp runtimeusers '{}' +
    find ${USER_HOME} -group runtimeusers -type d -perm /u+w -not -perm -g+w -exec chmod g+w '{}' +
fi
