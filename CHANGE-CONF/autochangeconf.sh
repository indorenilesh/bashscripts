#!/bin/sh

usage()
{
        echo "Usage: $0 <parameter>=<value> ";
        echo "Your input: $0 ${@}"
        echo "You need to provide parameter used in application.properties."
        exit 1;
}

if [ $# -ne 1 ]
then
        usage
fi

echo $1 | grep "="
VAL=`echo $?`
if [ $VAL -ne 0 ]
then
        usage
fi

SERVER_PREFIX=$(hostname -s | awk '{ if( substr($1,1,8)=="nukspgri" ) print "nukspgrip"; else if( substr($1,1,8)=="lonspgri") print "lonspgrip"; else if( substr($1,1,8)=="chispgri") print "chispgrip"; else if(substr($1,1,7)=="nukspqa") print "nukspqa"; else if(substr($1,1,8)=="nukspdev") print "nukspdev"; else print "invalid" }')
for srvr in 05 06 07 08 09 10 11 12 13 14
do
  ssh grip@${SERVER_PREFIX}${srvr} 'echo "$(hostname -s)"; sh -x /local/apps/grip/SCRIPTS/utilities/bin/changeconf.sh '$*' > /local/apps/grip/LOGS/changeconf.log'
done