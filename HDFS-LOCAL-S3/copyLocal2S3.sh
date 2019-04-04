#!/bin/bash

currentTradeDate=`date  +'%Y-%m-%d'`
tomorrowTradeDate=`date --date='+1 day' +'%Y-%m-%d'`
yesterdayTradeDate=`date --date='-1 day' +'%Y-%m-%d'`
LOG_DIR="/local/apps/grip/LOGS/COPY"
JOBLIMIT=@@JOB_LIMIT@@
fileCounter=0
jobCounter=0

S3_PATH=@@S3_BUCKET_NAME@@
LOCAL_DIR=@@LOCAL_COPY_FILE_PATH@@

#Ceated required directories
for DIR_NAME in ${LOCAL_DIR} ${LOG_DIR} ${LOCAL_DIR}/local_exch_list ${LOCAL_DIR}/DATA ${LOCAL_DIR}/DATA/derivativetick.parquet ${LOCAL_DIR}/DATA/derivativetick.parquet/tradeDate=${currentTradeDate}
do
        if [ ! -d ${DIR_NAME} ]
        then
            mkdir ${DIR_NAME}
        fi
done

#Check script is already running
if [ `ps aux |grep "copyLocal2S3.sh" |egrep -v "grep|vim|less|vi" |wc -l` -ne 2 ]
then
        echo -e "Previous job already running, skipping this." >> ${LOG_DIR}/copyLocal2S3_${currentTradeDate}.log
        exit 1
fi

echo -e "`date` - START" >> ${LOG_DIR}/copyLocal2S3_${currentTradeDate}.log

rm -rf ${LOCAL_DIR}/local_exch_list/*
for TD in ${currentTradeDate} ${tomorrowTradeDate} ${yesterdayTradeDate}
do

cd ${LOCAL_DIR}/local_exch_list
mkdir ${TD}

#Retrieving exchange id need to copy to s3 from local
ls ${LOCAL_DIR}/DATA/derivativetick.parquet/tradeDate=${TD} > ${LOCAL_DIR}/local_exch_list/${TD}/list.txt

if [ $? -ne 0 ]
then
        echo "No exchange still started for ${TD}" >> ${LOG_DIR}/copyLocal2S3_${TD}.log
        continue
fi

#Dividing exchanges in multiple jobs.
fileCounter=0
jobCounter=0
for i in `cat ${TD}/list.txt`
do
        fileCounter=`expr ${fileCounter} + 1`
        jobCounter=`expr ${jobCounter} + 1`
        awk 'NR=='${fileCounter} ${LOCAL_DIR}/local_exch_list/${TD}/list.txt >> ${LOCAL_DIR}/local_exch_list/${TD}/JOB${jobCounter}.txt
        if [ ${jobCounter} -eq ${JOBLIMIT} ]
        then
                jobCounter=0
        fi
done

#Running jobs
cd ${TD}
for i in `ls |grep ^JOB`
do
        (/local/apps/grip/SCRIPTS/utilities/bin/copyJob2S3.sh ${TD} ${LOCAL_DIR}/DATA/derivativetick.parquet/ ${S3_PATH}/derivativetick.parquet ${i} >> ${LOG_DIR}/copyJob2S3_${TD}.log &)
done

done
#Running single job for yesterday and tomorrow trade date
#for i in ${yesterdayTradeDate} ${tomorrowTradeDate}
#do
#       (/local/apps/grip/SCRIPTS/utilities/bin/copyJob2S3.sh ${i} ${LOCAL_DIR}/DATA/derivativetick.parquet ${S3_PATH}/derivativetick.parquet >> ${LOG_DIR}/copyJob2S3_${i}.log &) >> ${LOG_DIR}/copyJob2S3_${i}.out 2>&1
#done
#
#Don't dia till job doesn't completed.
while [ `ps aux |grep "copyJob2S3.sh" |egrep -v "grep|vim|less|vi" |wc -l` -ne 0 ]
do
        sleep 5
done

echo -e "`date` - END" >> ${LOG_DIR}/copyLocal2S3_${currentTradeDate}.log