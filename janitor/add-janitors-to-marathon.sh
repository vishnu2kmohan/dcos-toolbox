#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

for i in janitor-*.json
do 
    dcos marathon app add "${i}"
done
