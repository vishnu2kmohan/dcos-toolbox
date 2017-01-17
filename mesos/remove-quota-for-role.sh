#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

mesos_role=$1

echo "Removing Quota for role ${mesos_role}"

curl -skSL \
    -X DELETE \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/quota/${mesos_role}"
