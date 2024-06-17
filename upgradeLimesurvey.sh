#!/bin/bash
#set -x
#trap read debug
# Update existing Limesurvey installation
VERSION="0.6.2 20240617"
AUTHOR=js@crypto.koeln
TESTEDWITH=https://download.limesurvey.org/latest-master/limesurvey6.2.9+230925.zip
MYNAME=`basename $0 | cut -d. -f1`

# Draw a box around a text given as 1st argument with characters given as 2nd
drawBox() {
	block=${2:-"#"}

	for i in `seq 1 $((${#1} + 4))`
	do
		border="${border}${block}"
	done

	cat <<- EOF
		${border}
		${block} $1 ${block}
		${border}
	EOF
}

LOGFILE=${MYNAME}.log

# Write log entry with timestamp and hostname
writeLog() {
        echo "`date +%Y-%m-%d_%H:%M:%S_%Z` -  `hostname` - $1" | tee -a ${LOGFILE}
}

# read WORKDIR and DOMAIN from configuration file
. ${MYNAME}.ini

TIMESTAMP=`date +%Y%m%d%H%M%S`
BACKUP=${DOMAIN}_${TIMESTAMP}
DBDUMP=${BACKUP}.dmp
CONFIG=${WORKDIR}/${DOMAIN}/application/config/config.php
DBTYPE=`grep "[^#][[:space:]]*'connectionString' => " ${CONFIG} | cut -d"'" -f4|cut -d":" -f1`

drawbox "Preparations" "-"
writeLog "Detecting database parameters from ${CONFIG}" "-"

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

# Try to detect latest version URL by looking at the website
UPDATEURL=${1:-`curl https://community.limesurvey.org/downloads/ | grep "latest-master" | sed -e "s/.*href=.\(.*\)'.*/\1/"`}
UPDATEFILE=${UPDATEURL##*/}

if [ -z "${UPDATEURL}" ]
then
	echo "Please give URL for Limesurvey as first command line argument."
	exit 200
fi

writeLog "Update detected as ${UPDATEFILE}"

# Check whether logs claim there has already been a successful install
if [ -f "${LOGFILE}" ] && \
	INSTALLDATE="`grep \"${UPDATEFILE} successful\" ${LOGFILE} | cut -d' ' -f1`" && \
	[ -n "${INSTALLDATE}" ]
then
	echo "Warning: ${UPDATEFILE} has already been installed on ${INSTALLDATE}. Do you want to proceed (y/n)?"
	read REPLY

	if [ "${REPLY}" != "y" ]
	then
		exit 212
	fi
fi

# Check whether the latest version is already installed
INSTALLEDVERSION="`grep "'versionnumber'" ${WORKDIR}/${DOMAIN}/application/config/version.php | cut -d"'" -f4`"

if [[ "${UPDATEFILE}" =~ "${INSTALLEDVERSION}" ]]
then
	echo "Warning: The installed version ${INSTALLEDVERSION} is alteady the latest one. Do you want to proceed (y/n)?"
	read REPLY

	if [ "${REPLY}" != "y" ]
	then
		exit 213
	fi
fi

# Pre-installation checks finished. From here on data will be modified and maybe destroyed

drawBox "Performing update" "-"

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
mysqldump -u ${DBUSER} ${DBNAME} > ~/${DBDUMP}

if [ $? -ne 0 ] || [ ! -f ~/${DBDUMP} ]
then
	echo "Something went wrong when trying to create DB dump ${DBDUMP}."
	exit 205
fi

writeLog "Database ${DBUSER}@${DBNAME} exported."

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

if [ $? -ne 0 ]
then
	echo "Someting went wrong when trying to copy the update directory."
	exit 211
fi

writeLog "All data transferred to new installation."

drawBox "Cleanup"

echo "Have you tested the new version and want to archive the backed up data (y/n)?"
read REPLY

if [ "${REPLY}" = "y" ]
then
	tar cfvj ~/${MYNAME}_${TIMESTAMP}.tar.bz2 _${BACKUP} ~/${DBDUMP} --remove-files
fi

writelog "Installation of ${UPDATEFILE} successful." 
