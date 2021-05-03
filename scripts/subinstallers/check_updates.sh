#!/bin/bash

sudo apt-get update

UPDATES=$(sudo apt-get dist-upgrade -s --quiet=2 | grep ^Inst | wc -l)

if [[ "$UPDATES" -ne "0" ]]; then
    echo "Please run updates and reboot before installing Mistborn: sudo apt-get update && sudo apt-get -y dist-upgrade"
    exit 1;
fi