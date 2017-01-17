#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

quota_json_file=$1

mesos_role=$(jq '.role' ${1})

echo "Assigning Quota for role ${mesos_role}"

curl -skSL \
    -X POST \
    -d "@${quota_json_file}" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/quota"
