#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Verbosity level (e.g., 1, 2, 3)
glog_level=$1

# Duration to keep verbosity level toggled (e.g., 10secs, 15mins, etc.)
duration=$2   

echo "Toggling Apache Mesos GLOG_v to: ${glog_level} for ${duration}"

curl -skSL \
    -X GET \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/logging/toggle?level=${glog_level}&duration=${duration}"
