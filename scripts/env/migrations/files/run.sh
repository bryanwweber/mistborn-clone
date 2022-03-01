#!/bin/bash

AUG_ACTIONS=("add" "insert")
# add: put line after match
# insert: put line before match

mistborn_callsubmigrations() {
    folder="$1"

    for filename in $(find ${folder} -maxdepth 1 -type f -name "*.sh" | sort)
    do
        $filename "$@"
    done

}

mistborn_delFromFile() {
    folder="$1" #unused
    target_filename="$2"
    test_string="$3"

    sudo sed -i "/.*${test_string}.*/d" "${target_filename}"
}

mistborn_add2file() {

    folder="$1"
    action="$2"
    target_filename="$3"
    preceding_string="$4"
    target_string="$5"

    if [ "${preceding_string}" == "MISTBORN_TOP_OF_FILE" ]; then
        # put at the top of the file
        sudo sed -i "1s/^/${target_string}\n/" "${target_filename}"

    elif grep -q -e "${preceding_string}" "${target_filename}"; then


        if [ "${action}" == "insert" ]; then
            # insert before given line
            sudo sed -i "/.*${preceding_string}.*/i ${target_string}" "${target_filename}"

        elif [ "${action}" == "add" ]; then
            # add after given line
            sudo sed -i "/.*${preceding_string}.*/a ${target_string}" "${target_filename}"
        else
            echo "Unrecognized action: ${action}"
        fi

    else
        # add to bottom of file
        echo ${target_string} | sudo tee -a ${target_filename}
    fi

    mistborn_callsubmigrations "${folder}" "${action}" "${target_filename}" "${preceding_string}" "${target_string}"

}

mistborn_readfile() {
    folder="$1"
    filename="$2"

    # create file handle
    exec 5< ${filename}

    while read delimiter <&5 ; do
        read action <&5
        read target_filename <&5
        read test_string <&5
        read preceding_string <&5
        read target_string <&5

        if [ "${delimiter}" != "###" ]; then
            echo "migration file corrupt: ${delimiter} in ${filename}"
            exec 5<&-
            exit 1;
        fi

        if [ ! -f "${target_filename}" ]; then
            echo "file does not exist: ${target_filename}"
            exec 5<&-
            exit 1;
        fi

        echo "TARGET FILENAME: ${target_filename}"
        echo "TEST STRING: ${test_string}"
        echo "PRECEDING STRING: ${preceding_string}"
        echo "TARGET STRING: ${target_string}"

        
        if [ "${action}" == "delete" ]; then

            mistborn_delFromFile "${folder}" "${target_filename}" "${test_string}"

        elif [[ " ${AUG_ACTIONS[*]} " =~ "${action}" ]]; then

            if grep -q -e "${test_string}" "${target_filename}"; then

                echo "${test_string} already in ${target_filename}"
            
            else

                echo "${test_string} not in ${target_filename}"
                echo "adding ${target_string}"

                mistborn_add2file "${folder}" "${action}" "${target_filename}" "${preceding_string}" "${target_string}"
            fi
        else
            echo "No matching action found."
        fi
    
    done

    # close file handle
    exec 5<&-
}


mistborn_migrations() {
    folder="$1"

    echo "Folder name: ${folder}"

    for filename in $(find ${folder} -maxdepth 1 -type f -name "*.txt" | sort)
    do
        echo "file: ${filename}"
        mistborn_readfile "$folder" "$filename"
    done

}


# run migrations for all containing folders
for folder in $(find $(dirname "$0")/* -maxdepth 1 -type d -not -name "." | sort)
do
    mistborn_migrations "$folder"
done