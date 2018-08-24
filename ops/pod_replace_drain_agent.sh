#!bash

function mesos_agent_get_tasks () {
  local agent_id=$1

  curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/state" | \
  jq -er ".frameworks[].tasks[] | select(.slave_id==\"${agent_id}\") | select(.state==\"TASK_RUNNING\") | {id: .id, name: .name, framework_id: .framework_id, executor_id: .executor_id, state: .state}"
}

function mesos_framework_name_for_id() {
  local framework_id=$1
  curl -skSL \
    -H "Authorization: token=$(dcos config show core.dcos_acs_token)" \
    -H "Content-Type: application/json" \
    "$(dcos config show core.dcos_url)/mesos/frameworks?framework_id=${framework_id}" | \
  jq -er '.frameworks[].name'
}

echo "Getting the list of tasks on ${1} ..." > /dev/stderr
tasks=$(mesos_agent_get_tasks $1)
task_names=$(echo "${tasks}" | jq -er '.name')

for framework_id in $(echo "${tasks}" | jq -r .framework_id | uniq); do
  framework_name=$(mesos_framework_name_for_id ${framework_id})
  echo "Framework ${framework_name} has tasks on node." > /dev/stderr

  # Trick ahead: It doesnt really matter which sub-command to use, as long as its a SDK
  # service and name points to the correct framework.
  pod_list=$(dcos kafka --name="${framework_name}" pod list | jq -er '.[]' 2>/dev/null)
  [ "${pod_list}" != "" ] || continue
  for pod in ${pod_list}; do
    if echo "$task_names" | grep -qE "^${pod}"; then
      echo "Pod to issue replace for \"${pod}\":" > /dev/stderr
      echo "dcos kafka --name="${framework_name}" pod replace ${pod}"
    fi
  done
done
