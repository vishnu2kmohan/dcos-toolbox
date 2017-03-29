#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option LogLevel=quiet --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker pull mesosphere/spark:1.0.9-2.1.0-1-hadoop-2.6'" &) 2>/dev/null & done
wait

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option LogLevel=quiet --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker pull mesosphere/spark:1.0.6-2.0.2-hadoop-2.6'" &) 2>/dev/null & done
wait

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option LogLevel=quiet --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker pull mesosphere/spark:1.0.9-1.6.3-1-hadoop-2.6'" &) 2>/dev/null & done
wait

for i in $(dcos node --json | jq -er .[].id) ; do (dcos node ssh --option LogLevel=quiet --option StrictHostKeyChecking=no --option UserKnownHostsFile=/dev/null --option BatchMode=yes --option PasswordAuthentication=no --master-proxy --mesos-id="$i" "'docker images'" &) 2>/dev/null & done
wait
