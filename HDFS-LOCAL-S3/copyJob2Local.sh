#!/bin/bash

HADOOP_BIN_PATH=/local/apps/software/hadoop/bin
tradeDate=$1
tomorrowTradeDate=`date --date='+1 day' +'%Y-%m-%d'`
yesterdayTradeDate=`date --date='-1 day' +'%Y-%m-%d'`
LOG_DIR="/local/apps/grip/LOGS/COPY"

if [ $# -eq 4 ]
then
        if [ $2 ] && [ $3 ]
        then
                HDFS_PATH=$2
                LOCAL_PATH=$3
        else
                echo "No parameter passed. Provide HDFS and LOCAL path."
                exit
        fi
        for i in `cat $4`
        do
                        echo 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
                        echo "Starting data copy for ${i} for the trade date ${tradeDate} at `date`." 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
                        startTime=`date '+%s'`
                        ${HADOOP_BIN_PATH}/hadoop fs -get ${HDFS_PATH}/tradeDate=${tradeDate}/${i} ${LOCAL_PATH}/tradeDate=${tradeDate}/ 1>> ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
                        endTime=`date '+%s'`
                        echo "Data copy over for ${i} for the trade date ${tradeDate} at `date`. Total time taken $((endTime-startTime)) seconds." 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
                        echo 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
        done
elif [ $# -eq 3 ]
then
		if [ $2 ] && [ $3 ]
        then
                HDFS_PATH=$2
                LOCAL_PATH=$3
        else
                echo "No parameter passed. Provide HDFS and LOCAL path."
                exit
        fi	
		echo 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
        echo "Starting data copy for the trade date ${tradeDate} at `date`." 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
        startTime=`date '+%s'`
        ${HADOOP_BIN_PATH}/hadoop fs -get ${HDFS_PATH}/tradeDate=${tradeDate}/ ${LOCAL_PATH}/ 1>> ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
        endTime=`date '+%s'`
        echo "Data copy over for the trade date ${tradeDate} at `date`. Total time taken $((endTime-startTime)) seconds." 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
        echo 1>>  ${LOG_DIR}/copyJob2Local_${tradeDate}.log 2>> ${LOG_DIR}/copyJob2Local_${tradeDate}.out
else
        date >> ${LOG_DIR}/copyJob2Local_error${tradeDate}.log
        echo "Provide file with the list of exchanges." >> ${LOG_DIR}/copyJob2Local_error_${tradeDate}.log
fi
