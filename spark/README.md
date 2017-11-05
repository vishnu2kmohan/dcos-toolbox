# Demo Spark and HDFS on DC/OS

## Prerequisites

Spin up a 9 private agent, 1 public agent DC/OS 1.10 Stable cluster

## Install HDFS

```bash
dcos marathon app add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/hdfs/hdfs.json
```

Note: Wait for the HDFS service to deploy and go healthy

### Create the /history folder on HDFS

Log onto the Leading Mesos Master

```bash
dcos node ssh --master-proxy --leader
```

Pull down the HDFS client Docker Image

```bash
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
hdfs dfs -ls -h -R /
exit
exit
```

## Setup a Spark History Server to view Event Logs

```bash
dcos marathon app add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/spark/spark-history.json
```

## Setup a Spark Dispatcher (under UCR) configured to talk to the HDFS cluster

```bash
dcos marathon app add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/spark/spark-dispatcher-ucr-hdfs-eventlog.json
```

## Remotely exec into the Spark Dispatcher once it's healthy

```bash
dcos task exec -it spark-dispatcher-hdfs-eventlog bash
```

### Interactive Spark

You can now launch the interactive `spark-shell`, `pyspark` and `sparkR` shells

```bash
spark-shell
```

```bash
pyspark
```

```bash
sparkR
```

Note: `Ctrl-D` to exit the Interactive Spark shell(s)

### Run a Spark Job

Unset some envinonment variables that will interfere with `spark-submit`

```bash
unset MESOS_EXECUTOR_ID MESOS_FRAMEWORK_ID MESOS_SLAVE_ID MESOS_SLAVE_PID MESOS_TASK_ID
```

Launch a SparkPi job locally

```bash
spark-submit --verbose --name SparkPi-Local-2-2-0 --conf spark.cores.max=4 --conf spark.executor.cores=2 --class org.apache.spark.examples.SparkPi /opt/spark/dist/examples/jars/spark-examples_2.11-2.2.0.jar 100
```

Launch a SparkPi job consuming resources from Mesos in Client Mode

```bash
spark-submit --verbose --name SparkPi-Client-2-2-0 --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos --conf spark.cores.max=4 --conf spark.executor.cores=2 --conf spark.mesos.executor.docker.image=mesosphere/spark:2.1.0-2.2.0-1-hadoop-2.7 --class org.apache.spark.examples.SparkPi /opt/spark/dist/examples/jars/spark-examples_2.11-2.2.0.jar 100
```

Launch a SparkPi job against the Dispatcher in Cluster Mode

```bash
spark-submit --verbose --deploy-mode cluster --name SparkPi-Dispatcher-2-2-0 --master mesos://spark-dispatcher-hdfs-eventlog.marathon.l4lb.thisdcos.directory:7077 --conf spark.cores.max=4 --conf spark.executor.cores=2 --conf spark.mesos.executor.docker.image=mesosphere/spark:2.1.0-2.2.0-1-hadoop-2.7 --conf spark.executor.home=/opt/spark/dist --class org.apache.spark.examples.SparkPi http://downloads.mesosphere.com/spark/assets/spark-examples_2.11-2.0.1.jar 100
```

Launch a SparkPi job in local mode with the event logs sent to HDFS
```bash
spark-submit --verbose --name SparkPi-HDFS-Eventlog-Local-2-2-0 --conf spark.cores.max=4 --conf spark.driver.cores=1 --conf spark.driver.memory=1g --conf spark.executor.cores=2 --conf spark.executor.memory=1g --conf spark.executor.home=/opt/spark/dist --conf spark.eventLog.enabled=true --conf spark.eventLog.dir=hdfs://hdfs/history --class org.apache.spark.examples.SparkPi /opt/spark/dist/examples/jars/spark-examples_2.11-2.2.0.jar 100
```

Launch a SparkPi job in client mode with the event logs sent to HDFS
```bash
spark-submit --verbose --name SparkPi-HDFS-Eventlog-Client-2-2-0 --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos --conf spark.cores.max=4 --conf spark.driver.cores=1 --conf spark.driver.memory=1g --conf spark.executor.cores=2 --conf spark.executor.memory=1g --conf spark.mesos.executor.docker.image=mesosphere/spark:2.1.0-2.2.0-1-hadoop-2.7 --conf spark.executor.home=/opt/spark/dist --conf spark.eventLog.enabled=true --conf spark.eventLog.dir=hdfs://hdfs/history --conf spark.mesos.uris=http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml --class org.apache.spark.examples.SparkPi /opt/spark/dist/examples/jars/spark-examples_2.11-2.2.0.jar 100
```
Launch a SparkPi job in cluster mode with the event logs sent to HDFS

```bash
spark-submit --verbose --deploy-mode cluster --name SparkPi-HDFS-Eventlog-Dispatcher-2-2-0 --master mesos://spark-dispatcher-hdfs-eventlog.marathon.l4lb.thisdcos.directory:7077 --conf spark.cores.max=4 --conf spark.driver.cores=1 --conf spark.driver.memory=1g --conf spark.executor.cores=2 --conf spark.executor.memory=1g --conf spark.mesos.executor.docker.image=mesosphere/spark:2.1.0-2.2.0-1-hadoop-2.7 --conf spark.executor.home=/opt/spark/dist --conf spark.eventLog.enabled=true --conf spark.eventLog.dir=hdfs://hdfs/history --conf spark.mesos.uris=http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml --class org.apache.spark.examples.SparkPi http://downloads.mesosphere.com/spark/assets/spark-examples_2.11-2.0.1.jar 100
```

Note: You can see the event logs after the job completes from the Spark History Server UI

## `TeraGen`, `TeraSort` and `TeraValidate` 

### Add Spark Jobs to Metronome

```bash
dcos job add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/metronome/teragen.json
dcos job add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/metronome/terasort.json
dcos job add https://raw.githubusercontent.com/vishnu2kmohan/dcos-toolbox/master/metronome/teravalidate.json
```

### Run `TeraGen`, `TeraSort` and `TeraValidate`

#### `TeraGen`

```bash
dcos job run tera.gen
```

Note: Wait for the `TeraGen` job to complete

#### `TeraSort`

```bash
dcos job run tera.sort
```

Note: Wait for the `TeraSort` job to complete

#### `TeraValidate`

```bash
dcos job run tera.validate
```

Note: Wait for the `TeraValidate` job to complete
