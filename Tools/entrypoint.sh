#!/bin/bash
set -eu -o pipefail

if [ ! -x "$(which setup_tools.sh)" ] ; then
    echo "==> File setup_tools.sh not found."
    exit 1
fi

# Initialize the container
echo "==> Configuring tools image"
setup_tools.sh
echo "==> Tools container ready"

# If a CMD is passed, execute it
gosu $USERNAME "$@"
