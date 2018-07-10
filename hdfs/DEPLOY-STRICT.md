```bash
dcos security org service-accounts keypair hdfs-private-key.pem hdfs-public-key.pem

dcos security org service-accounts create -p hdfs-public-key.pem -d "Dev HDFS Service Account" dev_hdfs

dcos security secrets create-sa-secret --strict hdfs-private-key.pem dev_hdfs dev/hdfs/serviceCredential
dcos security secrets list /dev/hdfs

dcos security org users grant dev_hdfs dcos:mesos:master:task:user:nobody create --description "Allow dev_hdfs to launch tasks under the Linux user: nobody"
dcos security org users grant dev_hdfs dcos:mesos:master:task:app_id:/dev/hdfs create --description "Allow dev_hdfs to create tasks under the /dev/hdfs namespace"
dcos security org users grant dev_hdfs dcos:mesos:master:framework:role:dev__hdfs-role create --description "Allow dev_hdfs to register with Mesos and consume resources from the dev-hdfs role"
dcos security org users grant dev_hdfs dcos:mesos:master:reservation:role:dev__hdfs-role create --description "Allow dev__hdfs-role to reserve resources"
dcos security org users grant dev_hdfs dcos:mesos:master:reservation:principal:dev_hdfs create --description "Allow dev_hdfs principal to reserve resources"
dcos security org users grant dev_hdfs dcos:mesos:master:reservation:principal:dev_hdfs delete --description "Allow dev_hdfs principal to reserve resources"
dcos security org users grant dev_hdfs dcos:mesos:master:volume:role:dev__hdfs-role create --description "Allow dev__hdfs-role to access volumes"
dcos security org users grant dev_hdfs dcos:mesos:master:volume:principal:dev_hdfs create --description "Allow dev_hdfs principal to access volumes"
dcos security org users grant dev_hdfs dcos:mesos:master:volume:principal:dev_hdfs delete --description "Allow dev_hdfs principal to access volumes"
```
