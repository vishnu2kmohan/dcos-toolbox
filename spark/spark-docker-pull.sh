#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker pull mesosphere/spark:1.0.6-2.0.2-hadoop-2.6'" &) 2>/dev/null & done
wait

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker pull mesosphere/spark:1.0.5-1.6.3-hadoop-2.6'" &) 2>/dev/null & done
wait

#for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker pull mesosphere/spark:1.5.0-multi-roles-v2-bin-2.4.0'" &) 2>/dev/null & done
#

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker images'" &) 2>/dev/null & done
wait
