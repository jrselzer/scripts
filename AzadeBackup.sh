#!/bin/bash
# Backup hard disk to remote drive
VERSION="0.1 20161212"
AUTHOR=jrselzer@github.com

PIDFILE=/var/run/backup.pid
LOGFILE=/var/www/html/backup.log
USBDISK=/media/externe_platte
BUDIR=${USBDISK}/backup
BUMAILDIR=${USBDISK}/backup_mail
INFOMAIL=info@somedomain.tld

# Print current time
timestamp() {
	date "+%Y-%m-%d %H:%M:%S"
}

# Log into file
logline() {
	echo "`timestamp`: $1" | tee -a ${LOGFILE}
}

# Backup directory
logrsync() {
	rsync -av $1 $2 | tee -a ${LOGFILE}
}

if [ ! -f ${PIDFILE} ]
then
	STARTTIME="`timestamp`"
	echo $$ > ${PIDFILE}

	if [ -f ${LOGFILE} ] 
	then
		mv ${LOGFILE} ${LOGFILE}_`date +%Y%m%d%H%M%S`.bak
	fi

	mount /dev/sdb1 /media/externe_platte

	if [ $? -ne 0 ] 
	then
		logline "Error while mounting external disk, exiting."
		exit 42
	fi

	if [ -d ${BUDIR} ]
	then
		logline "Starting backup"
		logline "Saving drive Z"
		logrsync /mnt/windows/Z ${BUDIR}
		logline "Saving internal data"
		logrsync /mnt/windows/azade_intern ${BUDIR}
	else
		logline "No directory ${BUDIR} found on USB drive."	
	fi

	if [ -d ${BUMAILDIR} ]
	then
		logline "Saving mail inbox"
		logrsync /var/spool/mail ${BUMAILDIR}
		logline "Saving mail folders"
		logrsync /home/azade/mail ${BUMAILDIR}
	else
		logline "No directory ${BUMAILDIR} found on USB drive."
	fi

	umount ${USBDISK}
	mail -s "Backup ${STARTTIME}" \
		-r ${INFOMAIL} \
		${INFOMAIL} < ${LOGFILE}
	rm ${PIDFILE}
else
	BPID=$(< ${PIDFILE})

	if [ `ps -p ${BPID} | wc -l` -gt 1 ]
	then
		echo "Backup is already running"
	else
		logline "No running process found with PID ${BPID}), removing ${PIDFILE}."
		rm ${PIDFILE}
	fi
fi
