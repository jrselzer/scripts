#!/bin/bash
# copy current Moodle installation to a working new one
set -x
trap read debug
MYNAME=`basename $0 | cut -d. -f1`
VERSION="0.1 20250625"
TIMESTAMP=`date +%Y%m%d_%H%M%S`
DBBACKUP=${MYNAME}_${TIMESTAMP}.sql
PGPASS=~/.pgpass
OLD=1
NEW=2
DIR[${OLD}]=moodle_250418-103543
DIR[${NEW}]=moodle_5_attempt

for INST in ${OLD} ${NEW}
do
	CONF[${INST}]=${DIR[${INST}]}/config.php
	NAME[${INST}]=${DIR[${INST}]}
done

rsync -av ${DIR[${OLD}]}/ ${DIR[${NEW}]}
sed -i '12s/^..//;13s/^/\/\//;18s/^..//;19s/^/\/\//;15s/^..//;16s/^/\/\//' ${CONF[${NEW}]}

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
psql -d ${DBNAME[${NEW}]} \
	-U ${DBUSER[${NEW}]} \
	-h localhost < ${DBBACKUP}
mv ${PGPASS}_${TIMESTAMP} ${PGPASS}
