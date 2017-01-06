#!/usr/bin/env bash

set -o nounset -o pipefail

# frameworks_json is a JSON file with a list of (carefully filtered) frameworks to cleanup

# e.g., to filter completed frameworks based on a particular frameworkId:
# sh list-completed-non-star-frameworks.sh | jq -er '[.[] | select(.id | match("f24b4210-d154-4868-b97d-5c36d585b7db-0252"))]' > filtered-completed-non-star-frameworks.json

# e.g., to filter completed frameworks based on a particular framework name:
# sh list-completed-non-star-frameworks.sh | jq -er '[.[] | select(.name | match("confluent-kafka"))]' > filtered-completed-non-star-frameworks.json

# sh cleanup-frameworks.sh filtered-completed-non-star-frameworks.json

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
