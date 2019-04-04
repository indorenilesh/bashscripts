#!/bin/bash

tradeDate=$1
tomorrowTradeDate=`date --date='+1 day' +'%Y-%m-%d'`
yesterdayTradeDate=`date --date='-1 day' +'%Y-%m-%d'`
LOG_DIR="/local/apps/grip/LOGS/COPY"

if [ $# -eq 4 ]
then
        if [ $2 ] && [ $3 ]
        then
                LOCAL_PATH=$2
                S3_PATH=$3
        else
                echo "No parameter passed. Provide HDFS and LOCAL path."
                exit
        fi
        for i in `cat $4`
        do
                        echo "Starting data copy for ${i} for trade date ${tradeDate} at `date`." 1>>  ${LOG_DIR}/copyJob2S3_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2S3_${tradeDate}.out
                        startTime=`date '+%s'`
                        /usr/bin/aws s3 sync ${LOCAL_PATH}/tradeDate=${tradeDate}/${i} ${S3_PATH}/tradeDate=${tradeDate}/${i}
                        endTime=`date '+%s'`
                        echo "Data copy over for ${i} for trade date ${tradeDate} at `date`. Total time taken $((endTime-startTime)) seconds." 1>>  ${LOG_DIR}/copyJob2S3_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2S3_${tradeDate}.out
                        echo 1>>  ${LOG_DIR}/copyJob2S3_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2S3_${tradeDate}.out
        done
elif [ $# -eq 3 ]
then
	if [ $2 ] && [ $3 ]
    then
    	LOCAL_PATH=$2
        S3_PATH=$3
    else
    	echo "No parameter passed. Provide HDFS and LOCAL path."
        exit
    fi	
	echo "Starting data copy for trade date ${tradeDate} at `date`." 1>>  ${LOG_DIR}/copyJob2S3_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2S3_${tradeDate}.out
    startTime=`date '+%s'`
    /usr/bin/aws s3 sync ${LOCAL_PATH}/tradeDate=${tradeDate} ${S3_PATH}/tradeDate=${tradeDate}
    endTime=`date '+%s'`
    echo "Data copy over for trade date ${tradeDate} at `date`. Total time taken $((endTime-startTime)) seconds." 1>>  ${LOG_DIR}/copyJob2S3_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2S3_${tradeDate}.out
    echo 1>>  ${LOG_DIR}/copyJob2S3_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2S3_${tradeDate}.out
else
        date >> ${LOG_DIR}/copyJob2S3_error_${tradeDate}.log
        echo "Provide file with the list of exchanges." >> ${LOG_DIR}/copyJob2S3_error_${tradeDate}.log
fi
