#!/usr/bin/env bash                                                              
                                                                                
set -o errexit -o nounset -o pipefail

curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/state" | \
    jq -er '[.frameworks[] | select(.active==false) | select(.role != "*") | {id: .id, name: .name, role: .role, principal: .principal, active: .active, completed_tasks: ([.completed_tasks[] | {name: .name, framework_id: .framework_id, slave_id: .slave_id, resources: .resources}] | sort_by(.name))}] | sort_by(.name)' | \
    tee inactive-non-star-frameworks.json
