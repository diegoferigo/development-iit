#!/bin/bash
set -e

# Find the setup script
if [ ! -x "$(which setup_jaxsim.sh)" ] ; then
    echo "File setup_jaxsim.sh not found."
    exit 1
fi

# Initialize the container
echo "==> Configuring the 'diegoferigo/jaxsim' container..."
setup_jaxsim.sh
echo "==> ... done!"

# If a CMD is passed, execute it...
if [[ $(getent passwd | grep ${USER_NAME} | wc -l) -gt 0 ]] ; then
  # ... either directly as a user if it was created in the setup script
  gosu ${USER_NAME} "$@"
else
  # ... or as root otherwise.
  bash -ci "$@"
fi
