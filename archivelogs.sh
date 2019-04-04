#!/bin/sh

PATH=/usr/bin:/usr/sbin:/sbin:/bin:$PATH
export PATH
FS_THRESHOLD=80
MEM_THRESHOLD=80
TOTAL_MEM=$(free -g | grep "Mem" | awk '{print $2}')

cd /local/apps/grip

ls -lhR  /local/apps/grip/*/*/*.log.* |grep -v ".gz" | awk '{print $9}' | xargs gzip
find /local/apps/grip/ -type f -mtime +7 | egrep -v "backup" | egrep -i "\.gz|\.tar|\.zip" | xargs rm -rf
find /local/apps/grip/ -type f -name "start*[0-9].log" -mtime +3 | xargs rm -rf
find /local/apps/grip/ -type f -name "start*[0-9].out" -mtime +3 | xargs rm -rf
find /local/apps/grip/* -type f -name "*.csv" -mtime +7 | xargs rm -rf
find /local/apps/grip/ -type f -mtime +3 -name "*.xls" | xargs rm -rf
find /local/apps/grip/ -type f -mtime +7 -name "gc_*.log" | xargs rm -rf
find /local/apps/grip/ -type f -mtime +3 -name "ICL.log20*"  | xargs rm -rf
find /local/apps/grip/ -type f -mtime +3 -name "FeedCapture*.log*"  | xargs rm -rf
find /local/apps/core/ -type f -name core.java.* -mtime +3 | xargs rm -rf
find /local/apps/grip/grip-console/ -type f -mtime +3 -name "access.log*" | xargs rm -rf
find /local/apps/grip/grip-console/ -type f -mtime +3 -name "grip.log*" | xargs rm -rf
find /local/apps/grip/grip-console/gripDomain/logs/ -type f -mtime +3 -name "*.log*M" | xargs rm -f
find /local/apps/grip/grip-web/logs -type f -mtime +3 -name "*log.*" | xargs rm -f

# Delete 7 days old logs of COPY script and archieve last 5 days data.
find /local/apps/grip/LOGS/COPY -type f -mtime +7 | xargs rm -rf
find /local/apps/grip/LOGS/COPY -type f -mtime +1 | xargs gzip

#Delete 7 days old data from local and hdfs.
H_LISTDATES=`hdfs dfs -ls  hdfs://HCluster/grip/derivativetick.parquet/ |awk -F"/" '{print $NF}' |awk -F"=" '{print $2}' |grep ^20`
L_LISTDATES=`ls /local/apps/grip/HDFS/DATA/derivativetick.parquet |cut -c 11-`
KEEPDATES=`for i in {0..7} ; do date --date='-'$i' day' +'%Y-%m-%d' ; done`

for i in $L_LISTDATES
do
        echo $KEEPDATES |grep $i > /dev/null
        if [ $? -ne 0 ]
        then
                echo "Deleting data for tradeDate=$i"
                rm -rf /local/apps/grip/HDFS/DATA/derivativetick.parquet/tradeDate=$i
        fi
done

for i in $H_LISTDATES
do
        echo $KEEPDATES |grep $i > /dev/null
        if [ $? -ne 0 ]
        then
                echo "Deleting data for tradeDate=$i"
                hdfs dfs -rm -R hdfs://HCluster/grip/derivativetick.parquet/tradeDate=$i
        fi
done


# Ldap Backup deletion
find /local/apps/ldap/backup/ -type f -mtime +30 -name "LDAP_CONF*.tar" | xargs rm -rf
find /local/apps/ldap/backup/ -type f -mtime +30 -name "LDAP_DATA*.tar.gz" | xargs rm -rf
find /local/apps/ldap/backup/ -type f -mtime +30 -name "LDAP_LDIF*.ldif" | xargs rm -rf

echo "`hostname -s `_start@@ "
df -h
du -sh *

cd /local/apps/build/installapps/
SavePrevFile=`ls -ltrah *.tar | awk '{print $9}' | awk -F"_|-" '{print $3}' | sort -u | grep -v "[A-Za-z]" | tail -1 `
echo $SavePrevFile
ls -ltr *bkupdate*.tar | grep -v "$SavePrevFile" |awk '{print $9}' | xargs rm -rf

SavePkgFile=`ls -ltrah grip-*.zip | awk '{print $9}' | awk -F"_|-" '{print $3}' | sort -u | grep -v "[A-Za-z]" | tail -1 `
echo $SavePkgFile
ls -ltr grip-*.zip | grep -v "$SavePkgFile" |awk '{print $9}' | xargs rm -rf

cd /local/apps/grip/backup
SavePrevFile=`ls -ltrah *.tar | awk '{print $9}' | awk -F"_|-" '{print $3}' | sort -u | grep -v "[A-Za-z]" | tail -1 `
echo $SavePrevFile
ls -ltr *bkupdate*.tar | grep -v "$SavePrevFile" |awk '{print $9}' | xargs rm -rf

SavePkgFile=`ls -ltrah grip-*.zip | awk '{print $9}' | awk -F"_|-" '{print $3}' | sort -u | grep -v "[A-Za-z]" | tail -1 `
echo $SavePkgFile
ls -ltr grip-*.zip | grep -v "$SavePkgFile" |awk '{print $9}' | xargs rm -rf


TO_WARN=`df -h /local/apps/ | grep '/var/data' | awk  -v threshold=$FS_THRESHOLD '{if(strtonum(substr($4,1,length($4)-1))>threshold) print "YES"; else print "NO"; }'`
df -h /local/apps/ > /local/apps/grip/LOGS/systemFSalert.log
if [ "${TO_WARN}" = "YES" ] ; then
   mutt -e 'my_hdr From:'@@GRIPMAILFROM@@'' -s "GRIP File System Alert - exceeding ${FS_THRESHOLD}% disk usage on `hostname -s`" -b @@GRIPMAILTO@@ </local/apps/grip/LOGS/systemFSalert.log
fi


TO_WARN=`free -g | grep "buffers\/cache" | awk -v total=$TOTAL_MEM -v thld=$MEM_THRESHOLD '{if(($3*100/total)>thld) print "YES" ; else print "NO"; }'`
free -g > /local/apps/grip/LOGS/systemMEMalert.log
if [ "${TO_WARN}" = "YES" ] ; then
   mutt -e 'my_hdr From:'@@GRIPMAILFROM@@'' -s "GRIP System Memory Alert - exceeding ${MEM_THRESHOLD}% of heap `hostname -s`" -b @@GRIPMAILTO@@ </local/apps/grip/LOGS/systemMEMalert.log
fi

top -b -u grip -n 1 | egrep -iv "sshd|tail|bash|ping|top|grep|sleep|start|awk" | grep "grip" | awk '{print $1}' |xargs  ps -wF -p;top -b -u grip -n 1 | egrep -iv "sshd|tail|bash|ping|top|grep|sleep|start|awk" ; free -g

echo "`hostname -s `_end@@ "
