#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

for i in $(dcos marathon app list --json | jq -er '.[] | select(.id | match("nginx")) | .id')
do 
    dcos marathon app remove --force "${i}"
done
