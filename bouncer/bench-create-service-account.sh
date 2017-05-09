#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

private_key="service-account-bench-id_rsa"
public_key="service-account-bench-id_rsa.pub"

echo -n "Creating Service Account Keypair (4096 bit): "
(/usr/bin/time -f "real %e user %U sys %S" \
    dcos security org service-accounts keypair \
    -l 4096 \
    "${private_key}" \
    "${public_key}") 2>&1 | \
    tr "\n" " " \
    || true
echo

echo "Create-Service-Account,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
    echo -n "service-account-bench-${i},"
    (/usr/bin/time -f "%e,%U,%S" \
        dcos security org service-accounts create \
        -p "${public_key}" \
        -d "Service Account Benchmark ${i}" \
        "service-account-bench-${i}") 2>&1 | \
        tr "\n" " " \
        || true
    echo
done

#echo "Sleeping for 3 seconds for Zookeeper to settle"
sleep 3
dcos security org service-accounts show | grep service-account-bench || true
