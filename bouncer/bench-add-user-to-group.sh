#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Add-User-to-Group,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
    for j in $(seq "${3}" "${4}")
    do
        echo -n "add-user-$i-to-group-${j},"
        (/usr/bin/time -f "%e,%U,%S" \
            dcos security org groups add_user \
            "dcos-group-account-bench-$j" \
            "dcos-user-account-bench-$i") 2>&1 | \
            tr "\n" " " \
            || true
    echo
    done
done
