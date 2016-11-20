#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

dcos marathon app add spark-hdfs-history.json
