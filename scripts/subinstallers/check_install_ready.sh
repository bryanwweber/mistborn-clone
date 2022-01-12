#!/bin/bash

# check that platform is ready for installation

# check that netcat exists
if ! [ -x "$(command -v nc)" ]; then
    echo "Installing netcat"
    sudo apt-get install -y netcat
fi

# check port 80 is open
echo "Checking port 80"
if nc -z 127.0.0.1 80 > /dev/null; then
    echo "Port 80 is not available for mistborn"
    exit 1
else
    echo "Port 80 is available!"
fi
