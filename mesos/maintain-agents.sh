#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

maintenance_json_file=$1

# Set maintenance window to start five minutes from now
unavailability_start=$(python -c \
    "import time; print(int(time.time()*1000000000)+60000000000)")

machines=$(jq -e '[.windows[].machine_ids[].ip]' \
    "${maintenance_json_file}")
echo "Setting a Maintenance Schedule for the following machines: ${machines}"

# Substitute unavailability.start.nanoseconds from 1 to unavailability_start
maintenance_json=$(jq -er \
    ".windows[].unavailability.start.nanoseconds=$unavailability_start" \
    "${maintenance_json_file}")
echo "Maintenance Schedule: $maintenance_json"

curl -skSL \
    -X POST \
    -d "${maintenance_json}" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/maintenance/schedule" | \
    jq -er '.'

echo "Maintenance Status:"
curl -skSL \
    -X GET \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/maintenance/status" |\
    jq -er '.'
