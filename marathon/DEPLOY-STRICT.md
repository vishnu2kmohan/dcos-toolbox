```
dcos security org service-accounts keypair marathon-private-key.pem marathon-public-key.pem
dcos security org service-accounts create -p marathon-public-key.pem -d "Dev Marathon Service Account" dev_user_marathon
dcos security secrets create-sa-secret --strict marathon-private-key.pem dev_user_marathon dcos/dev/mom/user-marathon/serviceCredential

dcos security org users grant dev_user_marathon dcos:mesos:master:task:user:nobody create --description "Allow dev_user_marathon to launch tasks under the Linux user: nobody"
dcos security org users grant dev_user_marathon dcos:mesos:master:task:app_id:/dev/marathon create --description "Allow dev_user_marathon to create tasks under the /dev/marathon namespace"
dcos security org users grant dev_user_marathon dcos:mesos:master:framework:role:dev_user_marathon-role create --description "Allow dev_user_marathon to register with Mesos and consume resources from the dev-marathon role"
dcos security org users grant dev_user_marathon dcos:mesos:master:reservation:role:dev_user_marathon-role create --description "Allow dev_user_marathon-role to reserve resources"
dcos security org users grant dev_user_marathon dcos:mesos:master:reservation:principal:dev_user_marathon create --description "Allow dev_user_marathon principal to reserve resources"
dcos security org users grant dev_user_marathon dcos:mesos:master:reservation:principal:dev_user_marathon delete --description "Allow dev_user_marathon principal to reserve resources"
dcos security org users grant dev_user_marathon dcos:mesos:master:volume:role:dev_user_marathon-role create --description "Allow dev_user_marathon-role to access volumes"
dcos security org users grant dev_user_marathon dcos:mesos:master:volume:principal:dev_user_marathon create --description "Allow dev_user_marathon principal to access volumes"
dcos security org users grant dev_user_marathon dcos:mesos:master:volume:principal:dev_user_marathon delete --description "Allow dev_user_marathon principal to access volumes"

dcos marathon app add dev-MoM.json
```
