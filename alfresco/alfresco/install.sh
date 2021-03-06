#!/bin/bash
set -euo pipefail


### Init.
declare -r CUR=$(cd $(dirname $0); pwd)
. var.conf

pushd ${CUR}


#### Install mysql-5.7.
pushd ../../mysql/mysql-5.7/
./install.sh

# Import mysql root password.
. ./var.conf
popd


### Create Alfresco Database.
sed -e "s/#ALFRESCO_DB_NAME#/${ALFRESCO_DB_NAME}/" \
    -e "s/#ALFRESCO_DB_USER#/${ALFRESCO_DB_USER}/" \
    -e "s/#ALFRESCO_DB_PASS#/${ALFRESCO_DB_PASS}/" \
  ${CUR}/conf/create_database.sh.tmpl > ./create_database.sh

mysql -uroot -p${MYSQL_ROOT_PASS} < ./create_database.sh


### Install LibreOffice
yum -y install libreoffice


### Install Alfresco.
pushd /tmp

# Get Installer file.
curl -O ${INSTALLER_DOWNLOAD_URL}
declare -r installer_name=$(echo ${INSTALLER_DOWNLOAD_URL} | sed -e 's#http://.*/##')
chmod u+x ./${installer_name}

# Prepare install option file.
sed -e "s/#ALFRESCO_ADMIN_PASS#/${ALFRESCO_ADMIN_PASS}/" \
    -e "s/#ALFRESCO_DB_NAME#/${ALFRESCO_DB_NAME}/" \
    -e "s/#ALFRESCO_DB_USER#/${ALFRESCO_DB_USER}/" \
    -e "s/#ALFRESCO_DB_PASS#/${ALFRESCO_DB_PASS}/" \
 ${CUR}/conf/optionfile.tmpl > ./optionfile

# Install.
./${installer_name}  --optionfile ./optionfile

# Modify for office doc preview.
# Edit script and rename script file name.
sed -e 's/$SOFFICE_PORT\\;urp\\;/$SOFFICE_PORT;urp;/' \
  /opt/alfresco/libreoffice/scripts/libreoffice_ctl.sh > /opt/alfresco/libreoffice/scripts/ctl.sh
chmod a+x /opt/alfresco/libreoffice/scripts/ctl.sh

# Put JDBC Driver.
pushd /tmp
curl -O -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.43.tar.gz
tar -xzvf mysql-connector-java-5.1.43.tar.gz
cp ./mysql-connector-java-5.1.43/mysql-connector-java-5.1.43-bin.jar /opt/alfresco/tomcat/lib/
popd


### Starting...
service alfresco start


### End
popd
