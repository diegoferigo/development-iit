#!/bin/bash
set -eu -o pipefail

if [ ! -x "$(which setup_conda.sh)" ] ; then
    echo "==> File setup_conda.sh not found."
    exit 1
fi

# Initialize the container
echo "==> Configuring conda image"
setup_conda.sh
echo "==> Conda container ready"

# If a CMD is passed, execute it
gosu $USERNAME "$@"
