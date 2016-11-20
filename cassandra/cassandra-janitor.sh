#/usr/bin/env bash

set -o errexit -o nounset -o pipefail

docker run -it mesosphere/janitor /janitor.py -r cassandra-role -p cassandra-principal -z /dcos-service-cassandra --auth_token=
