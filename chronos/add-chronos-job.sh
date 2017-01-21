#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

chronos_json_file=$1

echo "Adding Chronos Job: $(jq '.name' ${chronos_json_file})"

curl -skSL \
    -X POST \
    -d "@${chronos_json_file}" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/service/chronos/v1/scheduler/iso8601"
