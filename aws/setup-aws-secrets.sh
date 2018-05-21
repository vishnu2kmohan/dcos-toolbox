#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

dcos security secrets create /dev/AWS_ACCESS_KEY_ID -v $(aws configure get se.aws_access_key_id)
dcos security secrets create /dev/AWS_SECRET_ACCESS_KEY -v $(aws configure get se.aws_secret_access_key)
