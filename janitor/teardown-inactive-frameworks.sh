#!/usr/bin/env bash

set -o nounset -o pipefail

# frameworks_json is a JSON file with a list of (carefully filtered) inactive frameworks

# e.g., to filter inactive frameworks based on  a particular frameworkId:
# sh list-inactive-non-star-frameworks.sh | jq -er '[.[] | select(.id | match("f24b4210-d154-4868-b97d-5c36d585b7db-0252"))]' > filtered-inactive-non-star-frameworks.json

# e.g., to filter inactive frameworks based on a particular framework name:
# sh list-inactive-non-star-frameworks.sh | jq -er '[.[] | select(.name | match("confluent-kafka"))]' > filtered-inactive-non-star-frameworks.json

# sh teardown-inactive-frameworks.sh filtered-inactive-non-star-frameworks.json

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
