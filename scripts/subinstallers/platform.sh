#!/bin/bash

# Get OS info
# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
DISTRO=""
VERSION_ID=""
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # use /etc/os-release to get distro 
    DISTRO=$(cat /etc/os-release | awk -F= '/^ID=/{print $2}')
    VERSION_ID=$(cat /etc/os-release | awk -F= '/^VERSION_ID=/{print $2}' | tr -d '"')
fi

figlet "UNAME: $UNAME"
figlet "DISTRO: $DISTRO"
figlet "VERSION: $VERSION_ID"


vercomp () {
    # case $? in
    #     0) op='=';;
    #     1) op='>';;
    #     2) op='<';;
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}