#!/usr/bin/env bash                                                              
                                                                                
set -o errexit -o nounset -o pipefail

curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/state" | \
    jq -er '[.frameworks[] | select(.active==true) | select(.name != "marathon") | select(.name != "metronome") |  {id: .id, name: .name, role: .role, principal: .principal, active: .active, tasks: ([.tasks[] | {name: .name, framework_id: .framework_id, slave_id: .slave_id, resources: .resources}] | sort_by(.name))}] | sort_by(.name)' | \
    tee active-non-star-frameworks.json
