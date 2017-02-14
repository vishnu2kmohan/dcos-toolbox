#!/usr/bin/env bash

#set -o errexit -o nounset -o pipefail

curl -skSL \
    -X GET \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/maintenance/status" |\
    jq -er '.'
