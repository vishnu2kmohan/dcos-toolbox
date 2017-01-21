#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

chronos_job_id=$1

echo "Stopping Chronos JobID: ${chronos_job_id}"

curl -skSL \
    -X DELETE \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/service/chronos/scheduler/task/kill/${chronos_job_id}"
