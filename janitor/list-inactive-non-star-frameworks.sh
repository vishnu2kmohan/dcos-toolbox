#!/usr/bin/env bash                                                              
                                                                                
set -o errexit -o nounset -o pipefail

# e.g., to filter inactive frameworks based on  a particular frameworkId:
# sh list-inactive-non-star-frameworks.sh | jq -er '[.[] | select(.id | match("f24b4210-d154-4868-b97d-5c36d585b7db-0252"))]' > filtered-inactive-non-star-frameworks.json

# e.g., to filter inactive frameworks based on a particular framework name:
# sh list-inactive-non-star-frameworks.sh | jq -er '[.[] | select(.name | match("confluent-kafka"))]' > filtered-inactive-non-star-frameworks.json

curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/state" | \
    jq -er '[.frameworks[] | select(.active==false) | select(.role != "*") | {id: .id, name: .name, role: .role, principal: .principal, active: .active, completed_tasks: ([.completed_tasks[] | {name: .name, framework_id: .framework_id, slave_id: .slave_id, resources: .resources}] | sort_by(.name))}] | sort_by(.name)' | \
    tee inactive-non-star-frameworks.json
