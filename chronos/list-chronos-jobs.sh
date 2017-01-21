#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Chronos Jobs:"

curl -skSL \
    -X GET \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/service/chronos/v1/scheduler/jobs" | \
    jq -er .[].name
