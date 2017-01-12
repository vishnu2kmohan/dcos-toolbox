#!/usr/bin/env bash

set -o nounset -o pipefail

exhibitor_znodes_json=$1

master_url=$(dcos config show core.dcos_url)/mesos/
marathon_url=$(dcos config show core.dcos_url)/marathon/v2/apps/
exhibitor_url=$(dcos config show core.dcos_url)/exhibitor/
token=$(dcos config show core.dcos_acs_token)

jq -er '. | keys[]' "${exhibitor_znodes_json}" | while read -r key ; do
        znode_title=$(jq -er ".[$key].title" "${exhibitor_znodes_json}")
        znode_key=$(jq -er ".[$key].key" "${exhibitor_znodes_json}")

        echo "Removing znode ${znode_title}: ${znode_key}"
        python janitor.py \
            -v \
            -m "${master_url}" \
            -n "${marathon_url}" \
            -e "${exhibitor_url}" \
            -z "${znode_key}" \
            --auth_token="${token}"
done
