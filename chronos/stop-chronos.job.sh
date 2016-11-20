#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Stopping Chronos Job: ${1}"

curl -skSL -X DELETE -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" "$(dcos config show core.dcos_url)/service/chronos/scheduler/task/kill/${1}"
