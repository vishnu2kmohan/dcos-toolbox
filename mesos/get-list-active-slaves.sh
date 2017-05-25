#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Getting list of *active* slaves from $(dcos config show core.dcos_url)"

curl -skSL \
    -X GET \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    "$(dcos config show core.dcos_url)/mesos/master/slaves" |
    jq -er '.slaves[] | select(.active==true) | .hostname'
