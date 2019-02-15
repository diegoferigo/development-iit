#!/bin/bash
set -eu -o pipefail

if [ ! -x "$(which setup_rl.sh)" ] ; then
    echo "==> File setup_rl.sh not found."
    exit 1
fi

# Initialize the container
echo "==> Configuring RL image"
setup_rl.sh
echo "==> RL container ready"

# If a CMD is passed, execute it
exec "$@"
