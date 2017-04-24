# Demo Alluxio Enterprise on DC/OS

## Prerequisites

Spin up a 12 private agent, 1 public agent DC/OS 1.9 Stable cluster

### Enable `MESOS_HOSTNAME_LOOKUP` and `MESOS_CGROUPS_LIMIT_SWAP`

Note: `MESOS_HOSTNAME_LOOKUP=true` requires properly configured DNS and is required (as a workaround) to improve data locality for Alluxio

_Ideally_, forward *and* reverse lookups for FQDNs, Short Hostnames and IP addresses should work:
* `hostname -f` *must* return the FQDN
* `hostname -s` *must* return the Short Hostname

For details on `MESOS_CGROUPS_LIMIT_SWAP` see: https://github.com/dcos/dcos/pull/1326

```bash
dcos node ssh --master-proxy --leader
MESOS_AGENTS=$(curl -sS master.mesos:5050/slaves | jq -er '.slaves[] | .hostname')
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no 'echo -e "MESOS_HOSTNAME_LOOKUP=true\nMESOS_CGROUPS_LIMIT_SWAP=true" | sudo tee -a /var/lib/dcos/mesos-slave-common && agent=`sudo systemctl status dcos-mesos-slave.service | grep "running" | wc -l` && if [ $agent = "1" ]; then sudo systemctl stop dcos-mesos-slave.service && sudo rm -f /var/lib/mesos/slave/meta/slaves/latest && sudo systemctl start dcos-mesos-slave.service --no-block; fi'; done
exit
```

### Permit insecure registry access to `registry.marathon.l4lb.thisdcos.directory`

```bash
dcos node ssh --master-proxy --leader
MESOS_AGENTS=$(curl -sS master.mesos:5050/slaves | jq -er '.slaves[] | .hostname')
command="sudo mkdir -p  /etc/systemd/system/docker.service.d/ && echo -e '[Service]\nEnvironmentFile=-/etc/sysconfig/docker\nEnvironmentFile=-/etc/sysconfig/docker-storage\nEnvironmentFile=-/etc/sysconfig/docker-network\nExecStart=\nExecStart=/usr/bin/docker daemon -H fd:// $OPTIONS $DOCKER_STORAGE_OPTIONS $DOCKER_NETWORK_OPTIONS $BLOCK_REGISTRY $INSECURE_REGISTRY --storage-driver=overlay --live-restore --insecure-registry registry.marathon.l4lb.thisdcos.directory:5000' | sudo tee --append /etc/systemd/system/docker.service.d/override.conf && sudo systemctl daemon-reload && sudo systemctl restart docker"
eval $command
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no $command; done
exit
```

## Setup the Docker Private Registry for Alluxio Client and Spark Docker Images

```bash
dcos marathon app add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/registry/registry.json
```

## Install HDFS as the Alluxio Under Store

```bash
dcos marathon app add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/hdfs/hdfs.json
```

Note: Wait for the service to deploy and go healthy

## Setup Alluxio

### License

Obtain your `alluxio-license.json` from Alluxio

Obtain the `base64`-encoded string of the Alluxio license as follows:
```bash
cat alluxio-license.json | base64 | tr -d "\n"
```

Insert that string into https://github.com/vishnu2kmohan/dcos-toolbox/blob/master/alluxio/alluxio-enterprise.json#L22

### Install Alluxio

```bash
dcos marathon app add alluxio-enterprise.json
```

Note: Wait for the deployment to complete

## Test Alluxio

### Validate the Alluxio install

```bash
dcos node ssh --master-proxy --leader
docker run -it registry.marathon.l4lb.thisdcos.directory:5000/alluxio/aee /bin/bash
```

Within the `aee` container:

```bash
./bin/alluxio runTests
./bin/alluxio fs ls /
exit
exit
```

### Check that the files have been persisted to HDFS as the Under Store

```bash
dcos node ssh --master-proxy --leader
docker run -it mesosphere/hdfs-client bash
```

Within the `hdfs-client` container:

```bash
export PATH=$PATH:/hadoop-2.6.4/bin
wget http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml
wget http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml
cp core-site.xml hadoop-2.6.4/etc/hadoop
cp hdfs-site.xml hadoop-2.6.4/etc/hadoop
hdfs dfs -mkdir -p /history
hdfs dfs -ls -R /
exit
exit
```

Note: We also created the `/history` folder to store Spark Event Logs, to be used later.

### Run a Spark Job on Alluxio

```bash
dcos node ssh --master-proxy --leader
docker run -it --net=host registry.marathon.l4lb.thisdcos.directory:5000/alluxio/spark-aee /bin/bash
```

From within the `spark-aee` container:
```                                              
./bin/spark-shell --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos --conf "spark.mesos.executor.docker.image=registry.marathon.l4lb.thisdcos.directory:5000/alluxio/spark-aee" --conf "spark.mesos.executor.docker.forcePullImage=false" --conf "spark.scheduler.minRegisteredResourcesRatio=1" --conf "spark.scheduler.maxRegisteredResourcesWaitingTime=5s" --conf "spark.driver.extraClassPath=/opt/spark/dist/jars/alluxio-enterprise-1.4.0-spark-client.jar" --conf "spark.executor.extraClassPath=/opt/spark/dist/jars/alluxio-enterprise-1.4.0-spark-client.jar" --executor-memory 1G
sc.setLogLevel("INFO")                                                          
val file = sc.textFile("alluxio://master-0-node.alluxio-enterprise.mesos:19998/default_tests_files/Basic_NO_CACHE_THROUGH")
file.count()
```

Note: `Ctrl+D` to exit from the Spark Scala Shell.

## Setup a Spark History Server to view Event Logs

```bash
dcos marathon app add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/spark/spark-history.json
```

## `TeraGen`, `TeraSort` and `TeraValidate` 

### Add Spark Jobs to Metronome

```bash
dcos job add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/alluxio/alluxio-teragen.json
dcos job add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/alluxio/alluxio-terasort.json
dcos job add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/alluxio/alluxio-teravalidate.json
```

### Run `TeraGen`, `TeraSort` and `TeraValidate`

#### `TeraGen`

```bash
dcos job run alluxio.tera.gen
```

Note: Wait for the `TeraGen` job to complete

#### `TeraSort`

```bash
dcos job run alluxio.tera.sort
```

Note: Wait for the `TeraSort` job to complete

#### `TeraValidate`
```bash
dcos job run alluxio.tera.validate
```

Note: Wait for the `TeraValidate` job to complete
