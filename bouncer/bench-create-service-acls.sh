#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Create-RID,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
    RID="dcos:adminrouter:service:service-bench-${i}"
    DESC="{\"description\": \"RID for ${RID}\"}"
    echo -n "${RID},"
    (/usr/bin/time -f "%e,%U,%S" \
        curl -skSL \
        -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
        -d "${DESC}" \
        "$(dcos config show core.dcos_url)/acs/api/v1/acls/${RID}") 2>&1 | \
        tr "\n" " " \
        || true
    echo
done

#echo "Sleeping for 3 seconds for Zookeeper to settle"
sleep 3
curl -skSL \
    -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    "$(dcos config show core.dcos_url)/acs/api/v1/acls" | \
    jq -er '.array[].rid' | grep "service-bench-" \
    || true

echo "Create-Service-Account-ACL,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
    RID="dcos:adminrouter:service:service-bench-${i}"
    ACL="${RID}/users/service-account-bench-${i}/full"
    DESC="{\"description\": \"ACL to dcos-group-account-bench-${i} for ${RID}\"}"
    echo -n "${ACL},"
    (/usr/bin/time -f "%e,%U,%S" \
        curl -skSL \
        -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
        -d "${DESC}" \
        "$(dcos config show core.dcos_url)/acs/api/v1/acls/${ACL}") 2>&1 | \
        tr "\n" " " \
        || true
    echo
done

echo "Create-Group-ACL,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
    RID="dcos:adminrouter:service:service-bench-${i}"
    ACL="${RID}/groups/dcos-group-account-bench-${i}/full"
    DESC="{\"description\": \"ACL to dcos-group-account-bench-${i} for ${RID}\"}"
    echo -n "${ACL},"
    (/usr/bin/time -f "%e,%U,%S" \
        curl -skSL \
        -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
        -d "${DESC}" \
        "$(dcos config show core.dcos_url)/acs/api/v1/acls/${ACL}") 2>&1 | \
        tr "\n" " " \
        || true
    echo
done

sleep 3
curl -skSL \
    -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    "$(dcos config show core.dcos_url)/acs/api/v1/acls" | \
    jq -er '.array[].acls' | grep "service-bench-" \
    || true
