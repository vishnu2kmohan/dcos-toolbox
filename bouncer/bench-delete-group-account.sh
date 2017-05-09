#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Delete-Group,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
   echo -n "dcos-group-account-bench-${i},"
   (/usr/bin/time -f "%e,%U,%S" \
       dcos security org groups delete \
       "dcos-group-account-bench-${i}") 2>&1 | \
       tr "\n" " " \
       || true
   echo
done

#echo "Sleeping for 3 seconds for Zookeeper to settle"
sleep 3
dcos security org groups show | grep dcos-group-account-bench || true
