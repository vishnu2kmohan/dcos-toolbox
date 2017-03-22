#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

docker run -it mesosphere/hdfs-client bash
wget http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml
wget http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml
cp core-site.xml hadoop-2.6.4/etc/hadoop
cp hdfs-site.xml hadoop-2.6.4/etc/hadoop
export PATH=$PATH:/hadoop-2.6.4/bin
hdfs dfs mkdir -p history
hdfs dfs -ls -R /
