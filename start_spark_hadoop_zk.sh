#!/bin/bash

ZK_HOST=@@BOX7@@:@@BOX8@@:@@BOX11@@:@@BOX12@@
HDFS_HOST=@@BOX7@@

for i in `echo $ZK_HOST | tr ':' ' '`
do
        echo "Starting zookeeper on $i .."
        ssh $i '/local/apps/software/zookeeper/bin/zkServer.sh start'
done


while true
do
    jps |grep QuorumPeerMain > /dev/null
        if [ `echo $?` -eq 0 ]
        then
                echo -e "\nStarting hadoop on $HDFS_HOST ...."
                ssh $HDFS_HOST '/local/apps/software/hadoop/sbin/start-dfs.sh'
                while true
                do
                        echo -n "."
                        sleep 2
                        NO_PROC=`jps |egrep 'NameNode|DataNode|DFSZKFailoverController' |wc -l`
                        if [ $NO_PROC -eq 3 ]
                        then
                                break
                        fi
                done
                break
        fi
done