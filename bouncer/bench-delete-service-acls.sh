#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Delete-Service-RID,Real,User,Sys"
for i in $(seq "${1}" "${2}")
do
    RID="dcos:adminrouter:service:service-bench-${i}"
    echo -n "${RID},"
    (/usr/bin/time -f "%e,%U,%S" \
        curl -skSL \
        -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
        "$(dcos config show core.dcos_url)/acs/api/v1/acls/${RID}") 2>&1 \
        | tr "\n" " " \
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
