#!/bin/bash

ZK_HOST=@@BOX7@@:@@BOX8@@:@@BOX11@@:@@BOX12@@
HDFS_HOST=@@BOX7@@

echo "Stoping hadoop ..."
ssh $HDFS_HOST '/local/apps/software/hadoop/sbin/stop-all.sh'

for i in `echo $ZK_HOST | tr ':' ' '`
do
        echo "Stoping zookeeper on $i ..."
        ssh $i '/local/apps/software/zookeeper/bin/zkServer.sh stop'
done