#!/bin/bash

INTERVAL="now -${1:-1} min"
SINCE=`date -d "${INTERVAL}" "+%s"`
OCDIR=/var/www/vhosts/wordpress/htdocs/owncloud

cd ${OCDIR}
/usr/local/bin/php occ user:list -i | \
	grep last_seen | \
	cut -d: -f2- | \
	while read LASTLOGIN
	do
		LASTLOGIN=`date -d "${LASTLOGIN}" "+%s"`

		if [ ${LASTLOGIN} -ge ${SINCE} ]
		then
			echo ${LASTLOGIN}
		fi
	done | \
	wc -l
