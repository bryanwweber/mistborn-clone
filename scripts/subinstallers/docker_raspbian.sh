#!/bin/bash

set +e

compare_version() {
  local versionOne="${1}"
  local comparision="${2}"
  local versionTwo="${3}"
  local result=
  local sortOpt=
  local returncode=1
 
  if [[ "${versionOne}" == "${versionTwo}" ]] ; then
    return 3
  fi
 
  case ${comparision} in
    lower|smaller|older|lt|"<" ) sortOpt= ;;
    higher|bigger|newer|bt|">" ) sortOpt='r' ;;
    * ) return 2 ;;
  esac
 
  result=($(printf "%s\n" "${versionOne}" "${versionTwo}" | sort -${sortOpt}V ))
  if [[ "${versionOne}" == "${result[0]}" ]] ; then
    returncode=0
  fi
 
  return ${returncode}
} # end of function compare_version

# libseccomp2
LIBSECCOMP2_VERSION=$(sudo -E apt-cache policy libseccomp2 | egrep ^\ *Inst | awk '{print $2}')

compare_version $LIBSECCOMP2_VERSION '<' '2.5.1-1'

if [ $? -eq 0 ]; then
    # this is dumb but the raspbian repo managers aren't impressive
    echo "Installing newer libseccomp2"
    pushd .
    cd /tmp
    wget http://ftp.us.debian.org/debian/pool/main/libs/libseccomp/libseccomp2_2.5.1-1_$(dpkg --print-architecture).deb
    sudo dpkg -i libseccomp2_2.5.1-1_$(dpkg --print-architecture).deb
    popd
fi

set -e