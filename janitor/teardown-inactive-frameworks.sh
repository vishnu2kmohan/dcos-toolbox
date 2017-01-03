#!/usr/bin/env bash

set -o nounset -o pipefail

frameworks_json=$1

master_url=$(dcos config show core.dcos_url)/mesos/
token=$(dcos config show core.dcos_acs_token)

jq -er '. | keys[]' "${frameworks_json}" | while read -r key ; do
        id=$(jq -er ".[$key].id" "${frameworks_json}")
        name=$(jq -er ".[$key].name" "${frameworks_json}")
        role=$(jq -er ".[$key].role" "${frameworks_json}")
        principal=$(jq -er ".[$key].principal" "${frameworks_json}")
        
        echo "Tearing down inactive framework: ${id} ${name} ${role} ${principal}"
        curl -skSL \
            -X POST \
            -H "Authorization: token=$token" \
            -H "Content-Type: application/json" \
            -d "frameworkId=${id}" \
            "${master_url}/master/teardown"
done
