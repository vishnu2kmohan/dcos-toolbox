#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

machines_json_file=$1

machines=$(jq -e '[.[].ip]' \
    "${machines_json_file}")

echo "Taking down the following machines for maintenance: ${machines}"

curl -skSL \
    -X POST \
    -d "@${machines_json_file}" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/machine/down" |\
    jq -er '.'
