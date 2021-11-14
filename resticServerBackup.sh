#!/bin/bash
VERSION="0.2 20211114"
AUTHOR=jrselzer@github.com
# This is the client-side counterpart to pullRestic.sh 

MYNAME=`basename $0 | cut -d. -f1`
TMPFILE=${MYNAME}.tmp
RESTIC=/var/www/vhosts/drupal/restic
REPO=/usr/home/dgbble/restic-backup
SERVER=rest:https://localhost:8000
CRT=res-server.crt
VHOST=/var/www/vhosts/drupal/htdocs
export GODEBUG=x509ignoreCN=0
BACKUP="${VHOST}/www.lernraum.net ${VHOST}/blog.forum-politische-bildung.de drupal_lernraum.dmp.bz2 drupal_bfpb.dmp.bz2"
PASS=.resticpwd

log() {
	echo "`date +%Y-%m-%d %H:%M:%S` $1"
}

case $1 in
	init)
		${RESTIC} \
			-r ${SERVER}  \
			--verbose \
			-p ${PASS} \
			init
		;;
	*)
		log "Dumping Lernraum DB"
                echo "[MYSQLDUMP]" > ${TMPFILE}
                chmod 600 ${TMPFILE}
                sed -e "s#\$CFG->dbhost[[:space:]]*=[[:space:]]'\(.*\)';#host = \1#; s#\$CFG->dbuser[[:space:]]*=[[:space:]]'\(.*\)';#user = \1#; s#\$CFG->dbpass[[:space:]]*=[[:space:]]'\(.*\)';#password = \1#" \
                        ${VHOST}/www.lernraum.net/config.php | \
                        egrep "^(host|user|password) = " >> ${TMPFILE}

                mysqldump --defaults-extra-file=${TMPFILE} drupal_lernraum | \
                        bzip2 -c9 > drupal_lernraum.dmp.bz2

		log "Dumping Wordpress DB"
		echo "[MYSQLDUMP]" > ${TMPFILE}
		sed -e "s#define('DB_USER', '\(.*\)');#user = \1#; s#define('DB_PASSWORD', '\(.*\)');#password = \1#; s#define('DB_HOST', '\(.*\)');#host = \1#" ${VHOST}/blog.forum-politische-bildung.de/wp-config.php | \
			egrep "^(host|user|password) = " >> ${TMPFILE}

		mysqldump --defaults-extra-file=${TMPFILE} drupal_bfpb | \
			bzip2 -c9 > drupal_bfpb.dmp.bz2

		rm ${TMPFILE}

		${RESTIC} \
			-r ${SERVER} \
			--verbose \
			--cacert ${CRT} \
			-p ${PASS} \
			backup ${BACKUP}
		;;
esac
