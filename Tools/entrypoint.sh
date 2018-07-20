#!/bin/bash
set -e

if [ ! -x "$(which setup_tools.sh)" ] ; then
    echo "File setup_tools.sh not found."
    exit 1
fi

# Initialize the container
setup_tools.sh

# If a CMD is passed, execute it
exec "$@"
