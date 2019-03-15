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
