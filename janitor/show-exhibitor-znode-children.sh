#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

#e.g.,  sh show-exhibitor-znode-children.sh /etcd

key=$1

curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/exhibitor/exhibitor/v1/explorer/node?key=${key}" | \
    jq -er '[.[] | {title: .title, key: .key}]' | \
    tee znode-children.json
