#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

chronos_job_id=$1

echo "Starting Chronos JobID: ${chronos_job_id}"

curl -skSL \
    -X PUT \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/service/chronos/v1/scheduler/job/${chronos_job_id}"
