#!/bin/sh
SERVER_PREFIX=$(hostname -s | awk '{ if( substr($1,1,8)=="nukspgri" ) print "nukspgrip"; else if( substr($1,1,8)=="lonspgri") print "lonspgrip"; else if( substr($1,1,8)=="chispgri") print "chispgrip"; else if(substr($1,1,7)=="nukspqa") print "nukspqa"; else if(substr($1,1,8)=="nukspdev") print "nukspdev";else if(substr($1,1,8)=="chispgri") print "chispgrip"; else if(substr($1,1,8)=="chispiis") print "chispiisp"; else if(substr($1,1,8)=="nukspiis") print "nukspiisp";else if(substr($1,1,8)=="lonspiis") print "lonspiisp"; else print "invalid" }')

# collect sysctl.conf from all the servers
for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14
do
scp ${SERVER_PREFIX}$i:/etc/sysctl.conf sysctl.conf-${SERVER_PREFIX}$i
done

# Function to compare 2 files
compare()
{
echo "${SERVER_PREFIX}$1 and ${SERVER_PREFIX}$2 " >> $3
echo "----------------------------------------------------" >> $3
file1=`ls |grep ${SERVER_PREFIX}$1`
file2=`ls |grep ${SERVER_PREFIX}$2`
diff $file1 $file2  |egrep ^"<|>" | awk '{print $2$3$4}' | grep -v ^'\#' |grep -v -e '^$' >> $3
echo "####################################################" >> $3
}

if [ ${SERVER_PREFIX} != 'nukspiisp' -o ${SERVER_PREFIX} != 'lonspiisp' -o ${SERVER_PREFIX} != 'chispiisp' ]
then
Report_FILE="GRIP_system_parameter_report.txt"
echo "Below are the list of conflicting parameters" >> $Report_FILE
echo "" >> $Report_FILE
compare 01 02 $Report_FILE
compare 03 04 $Report_FILE
compare 05 06 $Report_FILE
compare 07 08 $Report_FILE
compare 09 10 $Report_FILE
compare 11 12 $Report_FILE
compare 13 14 $Report_FILE
else
Report_FILE="T3_system_parameter_report.txt"
echo "Below are the list of conflicting parameters" >> $Report_FILE
echo "" >> $Report_FILE
compare 01 02 $Report_FILE
compare 01 03 $Report_FILE
compare 01 04 $Report_FILE
compare 05 06 $Report_FILE
compare 05 07 $Report_FILE
compare 05 08 $Report_FILE
fi
