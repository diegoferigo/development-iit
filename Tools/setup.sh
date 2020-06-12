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

# Enable colors in nanorc
echo "include /usr/share/nano/*.nanorc" > /home/$USERNAME/.nanorc
chown $USERNAME:$USERNAME /home/$USERNAME/.nanorc
