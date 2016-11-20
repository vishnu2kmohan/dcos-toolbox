#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

docker run -it mesosphere/hdfs-client bash
sed -i s/hdfs\.marathon\.mesos/marathon\.mesos/g configure-hdfs.sh
sed -i s/connect/connection/g configure-hdfs.sh
chmod +x configure-hdfs.sh
HDFS_SERVICE_NAME=hdfs ./configure-hdfs.sh 
export PATH=$PATH:/hadoop-2.6.4/bin
hdfs dfs -mkdir /history
hdfs dfs -ls -R /
exit
