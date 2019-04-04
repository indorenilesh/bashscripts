#!/bin/sh
ROOT_PATH="/local/apps/grip"

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

PARANAME=`echo $1 |awk -F "=" '{print $1}'`
PARAVAL=`echo $1 |awk -F "=" '{print $2}'`

echo $PARANAME
echo $PARAVAL

mkdir $ROOT_PATH/backup

cd $ROOT_PATH
for i in `find $ROOT_PATH -type f -name "application.properties"`
do
echo $i
CURRPARANAME=`grep -v '#' $i |grep -v -e '^$' |grep $PARANAME | awk -F"=" '{print $1}'`
CURRPARAVAL=`grep -v '#' $i |grep -v -e '^$' |grep $PARANAME | awk -F"=" '{print $2}'`
        if [ $CURRPARANAME == $PARANAME ]
        then
                if [ $PARANAME == "SITE_ACTIVE" ]
                then
                        if [ $PARAVAL == "YES" ] || [ $PARAVAL == "yes" ] || [ $PARAVAL == "NO" ] || [ $PARAVAL == "no" ]
                        then
                                if [ -d "$ROOT_PATH/ACTIVEMQ" ]
                                then
                                        if [ $PARAVAL == "YES" ] || [ $PARAVAL == "yes" ]
                                        then
                                                APPNAME=`echo $i |awk -F "/" '{print $5}'`
                                                cp -apv $i $ROOT_PATH/backup/${APPNAME}_application.properties_`date +%d_%b_%y_%H_%M`
                                                sed -i -e "s/$CURRPARANAME=$CURRPARAVAL/$PARANAME=$PARAVAL/g" $i
                                                cd $ROOT_PATH/ACTIVEMQ
                                                for k in `ls Broker**/config/amq.properties`
                                                do
                                                        APPNAME=`echo $k |awk -F "/" '{print $1}'`
                                                        cp -apv $k $ROOT_PATH/backup/${APPNAME}_amq.properties_`date +%d_%b_%y_%H_%M`
                                                        sed -i -e 's/.*SITE_ACTIVE=.*/SITE_ACTIVE=true/' -e 's/.*ROUTE_TO_REMOTE_ONE=.*/ROUTE_TO_REMOTE_ONE=true/' -e 's/.*ROUTE_TO_REMOTE_TWO=.*/ROUTE_TO_REMOTE_TWO=true/' $k
                                                done
                                        elif [ $PARAVAL == "NO" ] || [ $PARAVAL == "no" ]
                                        then
                                                APPNAME=`echo $i |awk -F "/" '{print $5}'`
                                                cp -apv $i $ROOT_PATH/backup/${APPNAME}_application.properties_`date +%d_%b_%y_%H_%M`
                                                sed -i -e "s/$CURRPARANAME=$CURRPARAVAL/$PARANAME=$PARAVAL/g" $i
                                                cd $ROOT_PATH/ACTIVEMQ
                                                for k in `ls Broker**/config/amq.properties`
                                                do
                                                        APPNAME=`echo $k |awk -F "/" '{print $1}'`
                                                        cp -apv $k $ROOT_PATH/backup/${APPNAME}_amq.properties_`date +%d_%b_%y_%H_%M`
                                                        sed -i -e 's/.*SITE_ACTIVE=.*/SITE_ACTIVE=false/' -e 's/.*ROUTE_TO_REMOTE_ONE=.*/ROUTE_TO_REMOTE_ONE=false/' -e 's/.*ROUTE_TO_REMOTE_TWO=.*/ROUTE_TO_REMOTE_TWO=false/' $k
                                                done
                                        fi
                                else
                                        APPNAME=`echo $i |awk -F "/" '{print $5}'`
                                        cp -apv $i $ROOT_PATH/backup/${APPNAME}_application.properties_`date +%d_%b_%y_%H_%M`
                                        sed -i -e "s/$CURRPARANAME=$CURRPARAVAL/$PARANAME=$PARAVAL/g" $i
                                fi
                        else
                                echo "Value of SITE_ACTIVE parameter is not correct."
                        fi
                else
                        APPNAME=`echo $i |awk -F "/" '{print $5}'`
                        cp -apv $i $ROOT_PATH/backup/${APPNAME}_application.properties_`date +%d_%b_%y_%H_%M`
                        sed -i -e "s/$CURRPARANAME=$CURRPARAVAL/$PARANAME=$PARAVAL/g" $i
                fi
        fi
done