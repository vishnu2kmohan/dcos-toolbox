```
dcos security org service-accounts keypair jenkins-private-key.pem jenkins-public-key.pem
dcos security org service-accounts create -p jenkins-public-key.pem -d "Dev Jenkins Service Account" dev_jenkins
dcos security secrets create-sa-secret --strict jenkins-private-key.pem dev_jenkins dev/jenkins/serviceCredential

dcos security org users grant dev_jenkins dcos:mesos:master:task:user:nobody create --description "Allow dev_jenkins to launch tasks under the Linux user: nobody"
dcos security org users grant dev_jenkins dcos:mesos:master:task:app_id:/dev/jenkins create --description "Allow dev_jenkins to create tasks under the /dev/jenkins namespace"
dcos security org users grant dev_jenkins dcos:mesos:master:framework:role:dev__jenkins__agent-role create --description "Allow dev_jenkins to register with Mesos and consume resources from the dev__jenkins__agent-role role"

tee dev-jenkins-agent-quota.json <<- 'EOF'
{
 "role": "dev__jenkins__agent-role",
 "guarantee": [
   {
     "name": "cpus",
     "type": "SCALAR",
     "scalar": { "value": 4.0 }
   },
   {
     "name": "mem",
     "type": "SCALAR",
     "scalar": { "value": 4096.0 }
   }
 ]
}
EOF

curl --cacert dcos-ca.crt -fsSL -X POST -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" $(dcos config show core.dcos_url)/mesos/quota -d @dev-jenkins-agent-quota.json

dcos marathon app add dev-jenkins-jenkins-01-docker-marathon.json
```
