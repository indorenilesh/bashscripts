#!/bin/bash

HADOOP_BIN_PATH=/local/apps/software/hadoop/bin
currentTradeDate=`date  +'%Y-%m-%d'`
tomorrowTradeDate=`date --date='+1 day' +'%Y-%m-%d'`
yesterdayTradeDate=`date --date='-1 day' +'%Y-%m-%d'`
LOG_DIR="/local/apps/grip/LOGS/COPY"
JOBLIMIT=@@JOB_LIMIT@@
fileCounter=0
jobCounter=0

HDFS_COMMON_PATH=@@FILE_STORE_LOCATION@@
LOCAL_DIR=@@LOCAL_COPY_FILE_PATH@@

#Ceated required directories
for DIR_NAME in ${LOCAL_DIR} ${LOG_DIR} ${LOCAL_DIR}/hdfs_exch_list ${LOCAL_DIR}/DATA ${LOCAL_DIR}/DATA/derivativetick.parquet ${LOCAL_DIR}/DATA/derivativetick.parquet/tradeDate=${currentTradeDate}
do
        if [ ! -d ${DIR_NAME} ]
        then
            mkdir ${DIR_NAME}
        fi
done

#Check script is already running
if [ `ps aux |grep "copyHdfs2Local.sh" |egrep -v "grep|vim|less|vi" |wc -l` -ne 2 ]
then
        echo -e "Previous job already running, skipping this." >> ${LOG_DIR}/copyHdfs2Local_${currentTradeDate}.log
        exit 1
fi

echo -e "`date` - START" >> ${LOG_DIR}/copyHdfs2Local_${currentTradeDate}.log


rm -rf ${LOCAL_DIR}/hdfs_exch_list/*
for TD in ${currentTradeDate} ${tomorrowTradeDate}
do

cd ${LOCAL_DIR}/hdfs_exch_list
mkdir ${TD}

#Retrieving exchange id need to copy to local from hdfs
${HADOOP_BIN_PATH}/hdfs dfs -ls ${HDFS_COMMON_PATH}/derivativetick.parquet/tradeDate=${TD} |grep ^d |awk -F"/" '{print $NF}' |grep -Ev ^$ > ${LOCAL_DIR}/hdfs_exch_list/${TD}/list.txt

if [ $? -ne 0 ]
then
        echo "No exchange still started for ${TD}" >> ${LOG_DIR}/copyHdfs2Local_${TD}.log
        continue
fi
#Dividing exchanges in multiple jobs.
fileCounter=0
jobCounter=0
for i in `cat ${TD}/list.txt`
do
        fileCounter=`expr ${fileCounter} + 1`
        jobCounter=`expr ${jobCounter} + 1`
        awk 'NR=='${fileCounter} ${LOCAL_DIR}/hdfs_exch_list/${TD}/list.txt >> ${LOCAL_DIR}/hdfs_exch_list/${TD}/JOB${jobCounter}.txt
        if [ ${jobCounter} -eq ${JOBLIMIT} ]
        then
                jobCounter=0
        fi
done

#Running jobs
cd ${TD}
for i in `ls |grep ^JOB`
do
        ( /local/apps/grip/SCRIPTS/utilities/bin/copyJob2Local.sh ${TD} ${HDFS_COMMON_PATH}/derivativetick.parquet/ ${LOCAL_DIR}/DATA/derivativetick.parquet ${i} >> ${LOG_DIR}/copyJob2Local_${TD}.log &)
done

done
#Running single job for yesterday and tomorrow trade date
#for i in ${yesterdayTradeDate} ${tomorrowTradeDate}
for i in ${yesterdayTradeDate}
do
( /local/apps/grip/SCRIPTS/utilities/bin/copyJob2Local.sh ${i} ${HDFS_COMMON_PATH}/derivativetick.parquet ${LOCAL_DIR}/DATA/derivativetick.parquet >> ${LOG_DIR}/copyJob2Local_${i}.log &) >> ${LOG_DIR}/copyJob2Local_${i}.out 2>&1
done


#Don't dia till job doesn't completed.
while [ `ps aux |grep "copyJob2Local.sh" |egrep -v "grep|vim|less|vi" |wc -l` -ne 0 ]
do
        sleep 5
done

#delete all 0 kb files.
find ${LOCAL_DIR}/DATA/ -size 0 |xargs rm -f

echo -e "`date` - END" >> ${LOG_DIR}/copyHdfs2Local_${currentTradeDate}.log