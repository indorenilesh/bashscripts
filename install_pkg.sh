#!/bin/bash

echo "Creating jbadmin user..."
useradd jbadmin -u 7004
chage -E -1 -M -1 -I -1 jbadmin

echo

echo "Installing required packages..."
PKG_LIST="httpd mod_ssl git"
GIT_TOKEN="d9ad373b05220a6c0b44338fa4139659c85c2cc5"
for i in $PKG_LIST
do
yum -y install $i
done

which git
if [ `echo $?` -eq 0 ]
then
        if [ -d /opt/jdks ]
        then
                cd /opt/jdks
        else
                mkdir /opt/jdks
                cd /opt/jdks
        fi
        git clone https://d9ad373b05220a6c0b44338fa4139659c85c2cc5@github.com/synchronecs/java-jdk.git
        ln -s java-jdk/jdk1.8.0_211 jdk_1.8
        chown jbadmin:jbadmin /opt/jdks -R
        chmod 755 /opt/jdks

        cd /opt
        git clone https://${GIT_TOKEN}@github.com/synchronecs/jboss-eap-7.2.git
        ln -s "jboss-eap-7.2" "jboss-eap-7"
        mkdir "/opt/jboss-eap-7/data"
        mkdir "/opt/jboss-eap-7/logs"
        mkdir "/opt/jboss-eap-7/tmp"
        chown jbadmin:jbadmin jboss* -R
        chmod 751 jboss-eap-7 -R
fi

echo

echo "Profile management steps..."
echo "export JAVA_HOME=/opt/jdks/jdk_1.8" > /etc/profile.d/jbadmin.sh
echo "export JBOSS_HOME=/opt/jboss-eap-7" >> /etc/profile.d/jbadmin.sh
echo "export PATH=\$JAVA_HOME/bin:\$JBOSS_HOME/bin:\$PATH" >> /etc/profile.d/jbadmin.sh
chmod 644 /etc/profile.d/jbadmin.sh

echo

echo "Configuring apache..."
cp -apv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf-`date +%m-%d-%Y`
echo "ServerName $HOSTNAME:80" >> /etc/httpd/conf/httpd.conf
systemctl stop httpd
systemctl start httpd
systemctl enable httpd
