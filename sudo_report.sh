#!/bin/sh

#Defining common parameters.
HOSTNAME=`hostname -s`
DATE=`date +%Y%m%d"_"%H%M`
HOSTID=`hostname -s | awk '{print substr($1,length($1)-1,length($1))}'`
SERVER_PREFIX=$(hostname -s | awk '{ if( substr($1,1,8)=="nukspgri" ) print "nukspgrip"; else if( substr($1,1,8)=="lonspgri") print "lonspgrip"; else if( substr($1,1,8)=="chispgri") print "chispgrip"; else if(substr($1,1,7)=="nukspqa") print "nukspqa"; else if(substr($1,1,8)=="nukspdev") print "nukspdev";else if(substr($1,1,8)=="chispgri") print "chispgrip"; else if(substr($1,1,8)=="chispiis") print "chispiisp"; else if(substr($1,1,8)=="nukspiis") print "nukspiisp";else if(substr($1,1,8)=="lonspiis") print "lonspiisp"; else print "invalid" }')
ENV=$(hostname -s | awk '{ if( substr($1,1,8)=="nukspgri" ) print "PROD"; else if( substr($1,1,8)=="lonspgri") print "LDR"; else if( substr($1,1,8)=="chispgri") print "CDR"; else if(substr($1,1,7)=="nukspqa") print "QA"; else if(substr($1,1,8)=="nukspdev") print "DEV"; else if(substr($1,1,8)=="chispiis") print "CDR"; else if(substr($1,1,8)=="nukspiis") print "PROD";else if(substr($1,1,8)=="lonspiis") print "LDR"; else print "invalid" }')
TMP_SUDO="/tmp/sudo_temp"

#Creating seperate log files report for GRIP/T3
echo $HOSTNAME |grep -i iisp
VAL=`echo $?`
if [ $VAL -eq 1 ]
then
        LOGFILE="/tmp/GRIP_sudo_report_"$HOSTNAME"_"$DATE".csv"
        Combine_Sheet="GRIP_Sudo_Report_"$DATE".csv"
else
        LOGFILE="/tmp/T3_sudo_report_"$HOSTNAME"_"$DATE".csv"
        Combine_Sheet="T3_Sudo_Report_"$DATE".csv"
fi
LOG_DIR="/tmp/sudoreport"
echo -e "Server,Date,UserName,Command" > $LOGFILE
echo >> $LOGFILE

# Report Month
Report_Month=`date -d "-1 days" | awk '{print $2}'`

# Getting data from secure log fiiles
for i in `ls -l /var/log |grep secure  | awk '{print $9}'`
do
grep sudo /var/log/$i |grep -Ev 'opamsrvc|pam_unix|incorrect|command not allowed|check_mk_agent|pam_sss\(sudo:auth\)|pam_sss\(sudo-i:auth\)' |grep $Report_Month >> $TMP_SUDO
done

#Creating Report in CSV format from Raw data
IFS=$'\n'
for i in `cat $TMP_SUDO`
do
        ONE=`echo $i |awk '{print $4","$1"-"$2" "$3","$6}'`
        TWO=`echo  $i |awk -F ";" '{print ","$4}'`
        echo $ONE $TWO >> $LOGFILE
done

#Uploading report on share drive
lftp sftp://realtime:realtime@204.109.130.135 -e "cd GRIP/Sudo_Report/UPLOAD; put $LOGFILE; bye"
rm -f $TMP_SUDO $LOGFILE

# Uploading report on share drive from box1 of each platform. (GRIP/T3)
if [ $SERVER_PREFIX = 'nukspgrip' -a $HOSTID -eq 01 -o $SERVER_PREFIX = 'nukspiisp' -a $HOSTID -eq 01 ]
then
        mkdir $LOG_DIR
        cd $LOG_DIR
        sleep 240
                if [ $SERVER_PREFIX = 'nukspgrip' -a $HOSTID -eq 01 ]
                then
                        lftp sftp://realtime:realtime@204.109.130.135 -e "cd GRIP/Sudo_Report/UPLOAD; mget -E GRIP*; bye"
                else
                        lftp sftp://realtime:realtime@204.109.130.135 -e "cd GRIP/Sudo_Report/UPLOAD; mget -E T3*; bye"
                fi
        echo -e "Server,Date,UserName,Command" >> $Combine_Sheet
        for i in `ls -rt $LOG_DIR`;
        do
                SRVS=`echo $i |awk -F"_" '{ print $3 }' | cut -d'.' -f1`
                cat $i |grep -v ^Server |grep -v ^[[:space:]]*$ >> $Combine_Sheet
                lftp sftp://realtime:realtime@204.109.130.135 -e "cd GRIP/Sudo_Report/OLDFILES; put $i; bye"
        done
        lftp sftp://realtime:realtime@204.109.130.135 -e "cd GRIP/Sudo_Report/;cd MONTHLY; put $Combine_Sheet; bye"
        cd /tmp
        rm -rf $LOG_DIR
fi