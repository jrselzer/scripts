#!/bin/bash
set -x
trap read debug
# Update existing Limesurvey installation
VERSION="0.4 20240519"
TESTEDWITH=https://download.limesurvey.org/latest-master/limesurvey6.2.9+230925.zip
MYNAME=`basename $0 | cut -d. -f1`
# read WORKDIR and DOMAIN from configuration file
. ${MYNAME}.ini

TIMESTAMP=`date +%Y%m%d%H%M%S`
BACKUP=${DOMAIN}_${TIMESTAMP}
CONFIG=${WORKDIR}/${DOMAIN}/application/config/config.php
DBTYPE=`grep "[^#][[:space:]]*'connectionString' => " ${CONFIG} | cut -d"'" -f4|cut -d":" -f1`

if [ "${DBTYPE}" != "mysql" ]
then
	echo "This script has only been configured to handle MySQL databases yet. Feel encouraged to change this."
	exit 207
fi

# Extract database user from configuration
DBUSER=`grep "[^#].*'username' =>" ${CONFIG} | cut -d"'" -f4`

if [ -z "${DBUSER}" ]
then
	echo "Could not find database user name in ${CONFIG}, please check."
	exit 208
fi

# Extract database name from configuration
DBNAME=`grep "[^#].*'connectionString' =>" ${CONFIG} | sed -e 's/.*dbname=\([^;]*\);.*/\1/'`

if [ -z "${DBNAME}" ]
then
	echo "Could not find database name in ${CONFIG}, please check."
	exit 209
fi

# Extract database password from configuration
export MYSQL_PWD=`grep "[^#].*'password' =>" ${CONFIG} | cut -d"'" -f4`

if [ -z "${MYSQL_PWD}" ]
then
	echo "Could not find database password in ${CONFIG}, please check."
	exit 210
fi

UPDATEURL=${1:-`curl https://community.limesurvey.org/downloads/ | grep "latest-master"|sed -e "s/.*href=.\(.*\)'.*/\1/"`}
UPDATEFILE=${UPDATEURL##*/}

if [ -z "${UPDATEURL}" ]
then
	echo "Please give URL for Limesurvey as first command line argument."
	exit 200
fi

cd ${WORKDIR} 

if [ $? -ne 0 ] || [ "`pwd`" != "${WORKDIR}" ]
then
	echo "Cannot access working directory ${WORKDIR}."
	exit 206
fi

# Backup current version
mv ${DOMAIN} _${BACKUP}

if [ $? -ne 0 ] || [ ! -d _${BACKUP} ]
then
	echo "Something went wrong when trying to move ${DOMAIN} to _${BACKUP}."
	exit 203
fi

# Create database backup
mysqldump -u ${DBUSER} ${DBNAME} > ~/${BACKUP}.dmp

if [ $? -ne 0 ] || [ ! -f ~/${BACKUP}.dmp ]
then
	echo "Something went wrong when trying to create DB dump ${BACKUP}.dmp."
	exit 205
fi

# Download update
wget ${UPDATEURL}

if [ $? -ne 0 ] || [ ! -f "${UPDATEFILE}" ]
then
	echo "Something went wrong when trying to download ${UPDATEFILE} from ${UPDATEURL}."
	exit 201
fi

# Extract downloaded update
unzip ${UPDATEFILE}

if [ $? -ne 0 ] || [ ! -d limesurvey ]
then
	echo "Someting went wrong when trying to unzip ${UPDATEFILE}."
	exit 202
fi

# Activate update
mv limesurvey ${DOMAIN}

if [ $? -ne 0 ] || [ ! -d "${DOMAIN}" ]
then
	echo "Someting went wrong when trying to move extracted data to ${DOMAIN}."
	exit 204
fi

# Copy configuration and uploaded data from backup to active version
cp _${BACKUP}/application/config/security.php ${DOMAIN}/application/config/
cp _${BACKUP}/application/config/config.php ${DOMAIN}/application/config/
cp -rav _${BACKUP}/upload/* ${DOMAIN}/upload

# Check whether copying the upload directory actually worked
diff -r _${BACKUP}/upload ${DOMAIN}/upload

if [ $? -ne 0 ]]
then
	echo "Someting went wrong when trying to copy the update directory."
	exit 211
fi

echo "Have you tested the new version and want to archive the backed up data (y/n)?"
read REPLY

if [ "${REPLY}" = "y" ]
then
	tar cfvj ../${MYNAME}_${TIMESTAMP}.tar.bz2 _${BACKUP} ~/${BACKUP}.dmp --remove-files
fi
