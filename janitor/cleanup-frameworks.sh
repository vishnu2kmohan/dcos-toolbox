#!/usr/bin/env bash

set -o nounset -o pipefail

frameworks_json=$1

master_url=$(dcos config show core.dcos_url)/mesos/
marathon_url=$(dcos config show core.dcos_url)/marathon/v2/apps/
exhibitor_url=$(dcos config show core.dcos_url)/exhibitor/
token=$(dcos config show core.dcos_acs_token)

jq -er '. | keys[]' "${frameworks_json}" | while read -r key ; do
        id=$(jq -er ".[$key].id" "${frameworks_json}")
        name=$(jq -er ".[$key].name" "${frameworks_json}")
        role=$(jq -er ".[$key].role" "${frameworks_json}")
        principal=$(jq -er ".[$key].principal" "${frameworks_json}")
        znode="dcos-service-${name}"
        echo "Cleaning up ${id} ${name} ${role} ${principal} ${znode}"

        python janitor.py \
            -m "${master_url}" \
            -n "${marathon_url}" \
            -e "${exhibitor_url}" \
            -r "${role}" \
            -p "${principal}" \
            -z "${znode}" \
            --auth_token="${token}"
done
