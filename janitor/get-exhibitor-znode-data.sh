#!/usr/bin/env bash

# e.g., To show znode data for /dcos-service-confluent-kafka/Configurations/22e6ce48-1f87-415c-8a35-c8caa270df68
# sh get-exhibitor-znode-data.sh /dcos-service-confluent-kafka/Configurations/22e6ce48-1f87-415c-8a35-c8caa270df68

set -o errexit -o nounset -o pipefail

key=$1

curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/exhibitor/exhibitor/v1/explorer/node-data?key=${key}" | \
    jq -er '.str'
