#!/bin/bash

# run migrations for all containing folders
for folder in $(find $(dirname "$0")/* -maxdepth 1 -type d -not -name "." | sort)
do
    ${folder}/run.sh
done
