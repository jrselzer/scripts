#!/bin/bash
set -x
trap read debug
# Update existing Limesurvey installation
VERSION="0.2 20240518"
TESTEDWITH=https://download.limesurvey.org/latest-master/limesurvey6.2.9+230925.zip
MYNAME=`basename $0 | cut -d. -f1`
. ${MYNAME}.ini

TIMESTAMP=`date +%Y%m%d%H%M%S`
BACKUP=${DOMAIN}_${TIMESTAMP}
CONFIG=${WORKDIR}/${DOMAIN}/application/config/config.php
DBUSER=`grep "[^#].*'username' =>" ${CONFIG} | cut -d"'" -f4`
DBNAME=`grep "[^#].*'connectionString' =>" ${CONFIG} | sed -e 's/.*dbname=\([^;]*\);.*/\1/'`
export MYSQL_PWD=`grep "[^#].*'password' =>" ${CONFIG} | cut -d"'" -f4`
UPDATEURL=$1
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

mv ${DOMAIN} _${BACKUP}

if [ $? -ne 0 ] || [ ! -d _${BACKUP} ]
then
	echo "Something went wrong when trying to move ${DOMAIN} to _${BACKUP}."
	exit 203
fi

mysqldump -u ${DBUSER} ${DBNAME} > ~/${BACKUP}.dmp

if [ $? -ne 0 ] || [ ! -f ~/${BACKUP}.dmp ]
then
	echo "Something went wrong when trying to create DB dump ${BACKUP}.dmp."
	exit 205
fi

wget ${UPDATEURL}

if [ $? -ne 0 ] || [ ! -f "${UPDATEFILE}" ]
then
	echo "Something went wrong when trying to download ${UPDATEFILE} from ${UPDATEURL}."
	exit 201
fi

unzip ${UPDATEFILE}

if [ $? -ne 0 ] || [ ! -d limesurvey ]
then
	echo "Someting went wrong when trying to unzip ${UPDATEFILE}."
	exit 202
fi

mv limesurvey ${DOMAIN}

if [ $? -ne 0 ] || [ ! -d "${DOMAIN}" ]
then
	echo "Someting went wrong when trying to move extracted data to ${DOMAIN}."
	exit 204
fi

cp _${BACKUP}/application/config/security.php ${DOMAIN}/application/config/
cp _${BACKUP}/application/config/config.php ${DOMAIN}/application/config/
cp -rav _${BACKUP}/upload/* ${DOMAIN}/upload

diff -r _${BACKUP}/upload ${DOMAIN}/upload
