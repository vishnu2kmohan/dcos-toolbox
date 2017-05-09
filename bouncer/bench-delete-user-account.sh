#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Delete-User,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
   echo -n "dcos-user-account-bench-${i},"
   (/usr/bin/time -f "%e,%U,%S" \
       dcos security org users delete \
       "dcos-user-account-bench-${i}") 2>&1 | \
       tr "\n" " " \
       || true
   echo
done

#echo "Sleeping for 3 seconds for Zookeeper to settle"
sleep 3
dcos security org users show | grep dcos-user-account-bench || true
