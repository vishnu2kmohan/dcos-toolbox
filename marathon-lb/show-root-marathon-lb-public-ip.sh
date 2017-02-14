#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

for agent in $(dcos marathon app show /dcos/root/marathon-lb | \
               jq -r .tasks[].host)
do
    echo $(dcos node ssh \
        --option LogLevel=quiet \
        --option StrictHostKeyChecking=no \
        --option UserKnownHostsFile=/dev/null \
        --option BatchMode=yes \
        --option PasswordAuthentication=no \
        --master-proxy --leader \
        "ssh -A -t \
            -o LogLevel=quiet \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o BatchMode=yes \
            -o PasswordAuthentication=no \
            ${agent} \
            curl -sSL http://ipecho.net/plain" 2>/dev/null)
done
