#!/usr/bin/env bash                                                              

set -o errexit -o nounset -o pipefail

curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/slaves" | \
    jq -er '[.slaves[] | select(.active==true) | {id: .id, hostname: .hostname, active: .active, reserved_resources_full: (.reserved_resources_full | del(.slave_public))}]' | \
    jq -er '[.[] | select(.reserved_resources_full | length > 0)]' | \
    tee non-public-agent-reservations.json
