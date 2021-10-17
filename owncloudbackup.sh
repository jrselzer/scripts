#!/bin/bash 
# Create a running Owncloud clone 
AUTHOR=jrselzer@github.com
VERSION="0.2 20211017"
MYNAME=`basename $0 | cut -d. -f1`
MYCONF=${MYNAME}.conf
if [ -f ${MYCONF} ]
then
	. ${MYCONF} 
else
	echo "Configuration file ${MYCONF} not found, exiting."
	exit 100
fi
TIMESTAMP=`date +%Y%m%d-%H%M%S`
DBBACKUP=${MYNAME}_${TIMESTAMP}.dmp

cat <<- EOF
	Creating database backup. Enter remote shell user password and then 
	database password
EOF

ssh ${RUSER}@${RHOST} mysqldump -u ${RDBUSER} -p ${RDBNAME} > ${DBBACKUP}

echo "Syncing installation. Enter remote shell user password"

rsync -av ${RUSER}@${RHOST}:${ROCDIR} ${WWWDIR}/
chmod 755 ${OCDIR}
chmod 644 ${OCDIR}/.htaccess

echo "Replacing datafile paths in ${DBBACKUP}"

ROCDATA=`grep datadirectory ${OCCONF} | cut -d"'" -f4`
sed -i 's?'${ROCDATA}'?'${OCDATA}'?g' ${DBBACKUP}

echo "Importing ${DBBACKUP}"

mysql --login-path=ocbackup ${DBNAME} < ${DBBACKUP}

echo "Adapting config"

OCDATA=${OCDATA//\//\\/}

sed -i "s/\('datadirectory' => '\).*/\1${OCDATA}',/; \
        s/\('dbname' => '\).*'/\1${DBNAME}'/; \
        s/\('dbuser' => '\).*'/\1${DBUSER}'/; \
        s/\('dbpassword' => '\).*'/\1${DBPASS}'/; \
        s/\(0 => '\).*'/\1${DOMAIN}'/" \
        ${OCCONF}

echo "Re-scanning data directory to make non-indexed files visible"

cd ${OCDIR}
php occ files:scan --all
