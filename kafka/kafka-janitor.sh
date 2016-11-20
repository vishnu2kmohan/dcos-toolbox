#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

docker run -it mesosphere/janitor /janitor.py -r kafka-role -p kafka-principal -z dcos-service-kafka --auth_token=
