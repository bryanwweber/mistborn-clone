#!/bin/bash

set -e

folder="$1" 
action="$2"
target_filename="$3" 
preceding_string="$4" 
target_string="$5" 

TMP_FILE="$(mktemp)"

echo "submigrations: live rule push"

if [ "${target_filename}" == "/etc/iptables/rules.v4" ]; then

    sudo iptables-save > ${TMP_FILE}

    if [ "${preceding_string}" == "MISTBORN_TOP_OF_FILE" ]; then

        # top
        sed -i "1s/^/${target_string}\n/" "${TMP_FILE}"

    elif grep -q -e "${preceding_string}" "${TMP_FILE}"; then

        if [ "${action}" == "insert" ]; then
            # before
            sed -i "/.*${preceding_string}.*/i ${target_string}" "${TMP_FILE}"
        elif [ "${action}" == "add" ]; then
            # after
            sed -i "/.*${preceding_string}.*/a ${target_string}" "${TMP_FILE}"
        else
            echo "Unrecognized action: ${action}"
        fi

    else
        # bottom
        echo ${target_string} >> ${TMP_FILE}
    fi

    sudo iptables-restore < ${TMP_FILE}
    rm -f ${TMP_FILE}

fi
