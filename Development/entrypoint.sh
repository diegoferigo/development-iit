#!/bin/bash
set -eu -o pipefail

if [ ! -x "$(which setup_development.sh)" ] ; then
    echo "==> File setup_development.sh not found."
    exit 1
fi

# Initialize the container
echo "==> Configuring development image"
setup_development.sh
echo "==> Development container ready"

# If a CMD is passed, execute it
gosu $USERNAME "$@"
