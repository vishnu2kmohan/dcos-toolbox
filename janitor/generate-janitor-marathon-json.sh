#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

frameworks_json=$1

jq -er '. | keys[]' "${frameworks_json}" | while read -r key ; do
        id=$(jq -er ".[$key].id" "${frameworks_json}")
        name=$(jq -er ".[$key].name" "${frameworks_json}")
        role=$(jq -er ".[$key].role" "${frameworks_json}")
        principal=$(jq -er ".[$key].principal" "${frameworks_json}")
        znode="dcos-service-${name}"
        token=$(dcos config show core.dcos_acs_token)

        echo "Setting up janitor to cleanup framework: ${id} ${name} ${role} ${principal} ${znode}"
        sed -e "s|__ROLE__|${role}|g" \
            -e "s|__PRINCIPAL__|${principal}|g" \
            -e "s|__ZNODE__|${znode}|g" \
            -e "s|__TOKEN__|${token}|g" \
            -e "s|__NAME__|${name}|g" \
            template-janitor-marathon.json > "janitor-${name}-marathon.json"
done
