#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Adding Chronos Job: $(jq '.name' ${1})"

curl -skSL -X POST -d "@${1}" -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" "$(dcos config show core.dcos_url)/service/chronos/scheduler/iso8601"
