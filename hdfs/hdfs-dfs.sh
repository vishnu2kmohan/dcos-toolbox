#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

export HADOOP_CONF_DIR="${MESOS_SANDBOX}"
export PATH=$PATH:/hadoop-2.6.4/bin

#cd "${MESOS_SANDBOX}"
#docker run -it mesosphere/hdfs-client bash
#wget http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml
#wget http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml
#cp core-site.xml hadoop-2.6.4/etc/hadoop
#cp hdfs-site.xml hadoop-2.6.4/etc/hadoop

hdfs dfs -ls -R /
