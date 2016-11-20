#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

docker run -it mesosphere/janitor /janitor.py -r hdfs-role -p hdfs-principal -z dcos-service-hdfs --auth_token=
