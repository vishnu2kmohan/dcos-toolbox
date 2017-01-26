#!/usr/bin/env bash

#set -o errexit -o nounset -o pipefail

maintenance_json_file=$1

# Set maintenance window to start five minutes from now
unavailability_start=$(python -c \
    "import time; print(int(time.time()*1000000000)+60000000000)")

machines=$(jq -e '[.windows[].machine_ids[].ip]' \
    "${maintenance_json_file}")
echo "Setting maintenance schedule for the following machines: ${machines}"

# Substitute unavailability.start.nanoseconds to currrent time in nanoseconds
maintenance_json=$(jq -er \
    ".windows[].unavailability.start.nanoseconds=$unavailability_start" \
    "${maintenance_json_file}")
echo "Maintenance Schedule: $maintenance_json"

curl -fskSL \
    -X POST \
    -d "${maintenance_json}" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/maintenance/schedule" | \
    jq -er '.'

curl -fskSL \
    -X GET \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/maintenance/status" |\
    jq -er '.'
