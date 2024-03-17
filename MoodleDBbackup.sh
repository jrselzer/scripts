#!/bin/bash 
VERSION="0.2 20240316"
AUTHOR=
# creates database dump of a Moodle installation

CONFIG=/usr/home/dgbble/public_html/webwurzel/moodle/config.php
PGPASS=~/.pgpass

if [ ! -f ${CONFIG} ]
then
	echo "Fatal: No configuration file ${CONFIG} found."
	exit 102
fi

TIMESTAMP=`date +%Y%m%d-%M%M%S`

DBTYPE=`grep "^\\$CFG->dbtype" ${CONFIG} | cut -d\' -f2`
DBHOST=`grep "^\\$CFG->dbhost" ${CONFIG} | cut -d\' -f2`
DBNAME=`grep "^\\$CFG->dbname" ${CONFIG} | cut -d\' -f2`
DBUSER=`grep "^\\$CFG->dbuser" ${CONFIG} | cut -d\' -f2`
DBPASS=`grep "^\\$CFG->dbpass" ${CONFIG} | cut -d\' -f2`


case ${DBTYPE} in
	mariadb)
		mysqldump -u ${DBUSER} \
			-p"${DBPASS}" \
			${DBNAME} > ${DBNAME}_${TIMESTAMP}.dmp
		;;
	pgsql)
                touch ${PGPASS}
                chmod 600 ${PGPASS}
		echo "${DBHOST}:5432:${DBNAME}:${DBUSER}:${DBPASS}" > ${PGPASS}

		pg_dump -U ${DBUSER} \
			 -d ${DBNAME} > moodlePG_${TIMESTAMP}.sql
		;;
	*)
		echo "Fatal: Unknown database type ${DBTYPE}"
		exit 103
		;;
esac
