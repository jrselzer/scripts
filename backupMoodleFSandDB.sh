#!/bin/bash
# copy current Moodle installation to a working new one
#set -x
#trap read debug
MYNAME=`basename $0 | cut -d. -f1`
VERSION="0.2 20250905"
TIMESTAMP=`date +%Y%m%d_%H%M%S`
DBBACKUP=${MYNAME}_${TIMESTAMP}.sql
PGPASS=~/.pgpass
OLD=1
NEW=2
DIR[${OLD}]=moodle_250418-103543
DIR[${NEW}]=moodle_5_attempt

CONFIRM=`cat /dev/urandom | tr -dc [[:alnum:]] | head -c 8`

for INST in ${OLD} ${NEW}
do
	CONF[${INST}]=${DIR[${INST}]}/config.php
	NAME[${INST}]=${DIR[${INST}]}
done

rsync -av ${DIR[${OLD}]}/ ${DIR[${NEW}]}

# deactivate database configuration entries in lines 13, 16 and 19, activate lines 12, 15 and 18
sed -i '12s/^..//;13s/^/\/\//;18s/^..//;19s/^/\/\//;15s/^..//;16s/^/\/\//' ${CONF[${NEW}]}

# get database settings from configuration file
for INST in ${OLD} ${NEW}
do
	DBHOST[${INST}]=`grep "^\\$CFG->dbhost" ${CONF[${INST}]} | cut -d\' -f2`
	DBNAME[${INST}]=`grep "^\\$CFG->dbname" ${CONF[${INST}]} | cut -d\' -f2`
	DBUSER[${INST}]=`grep "^\\$CFG->dbuser" ${CONF[${INST}]} | cut -d\' -f2`
	DBPASS[${INST}]=`grep "^\\$CFG->dbpass" ${CONF[${INST}]} | cut -d\' -f2`
done

# cat ${DIR[${NEW}]}/config.php

echo "exporting current database"
mv ${PGPASS} ${PGPASS}_${TIMESTAMP}
echo "localhost:5432:${DBNAME[${OLD}]}:${DBUSER[${OLD}]}:${DBPASS[${OLD}]}" > ${PGPASS}
chmod 600 ${PGPASS}
cat ${PGPASS}
pg_dump -U ${DBUSER[${OLD}]} \
	-d ${DBNAME[${OLD}]} \
	--clean \
	-f ${DBBACKUP}
mv ${PGPASS}_${TIMESTAMP} ${PGPASS}

rm ${NAME[${NEW}]}.sql && ln -s ${DBBACKUP} ${NAME[${NEW}]}.sql
ls -l ${DBBACKUP}

echo "importing database copy"
mv ${PGPASS} ${PGPASS}_${TIMESTAMP}
echo "localhost:5432:${DBNAME[${NEW}]}:${DBUSER[${NEW}]}:${DBPASS[${NEW}]}" > ${PGPASS}
chmod 600 ${PGPASS}
cat ${PGPASS}

echo "enter ${CONFIRM} if you want to empty ${NAME[${NEW}]} before importing data"
read REPLY

if [ "${REPLY}" = "${CONFIRM}" ]
then
	echo "removing all data from ${NAME[${NEW}]}"
	psql -d ${DBNAME[${NEW}]} \
		-U ${DBUSER[${NEW}]} \
		-h localhost < ${DBBACKUP} << EOF
	drop schema public cascade;
	create schema public;
EOF
fi 

psql -d ${DBNAME[${NEW}]} \
	-U ${DBUSER[${NEW}]} \
	-h localhost < ${DBBACKUP}
mv ${PGPASS}_${TIMESTAMP} ${PGPASS}

echo "enter ${CONFIRM} if you want to continue and migrate ${NAME[${NEW}]} to the latest major release"
read REPLY

if [ "${REPLY}" != "${CONFIRM}" ]
then
	echo "You have now a working copy of your Moodle installation under ${DIR[${NEW}]}"
	exit 1
fi

echo "bringing ${NAME[${NEW}]} to latest major release"
cd ${NAME[${NEW}]}
git branch --track MOODLE_500_STABLE origin/MOODLE_500_STABLE
git checkout MOODLE_500_STABLE
php admin/cli/upgrade.php
