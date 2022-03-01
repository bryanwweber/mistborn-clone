#!/bin/bash

binaries=("pwgen" "curl")

for bin in "${binaries[@]}"
do

    if ! [ -x "$(command -v ${bin})" ]; then
        echo "Installing ${bin}"
        sudo apt-get install -y ${bin}
    fi

done

