#!/bin/bash

BASEDIR=/var/www/vhosts/wordpress/zabbix
PIDFILE=${BASEDIR}/zabbix_agentd.pid
AGENTPID=`[ -f ${PIDFILE} ] && cat ${PIDFILE}`
HOME=${BASEDIR}
OPTIONS="-f"

start() {
	if [ -f ${PIDFILE} ]
	then
		echo "${PIDFILE} already exists, not starting."
		exit 102
	else
		${BASEDIR}/sbin/zabbix_agentd \
			${OPTIONS} \
			-c ${BASEDIR}/conf/zabbix_agentd.conf
	fi
}

stop() {
	if [ -f ${PIDFILE} ]
	then
		kill ${AGENTPID}
	else
		echo "${PIDFILE} not found, please kill process manually."
		exit 103
	fi
}

case $1 in
	start)
		echo "starting Zabbix agent"
		start
		;;
	stop)
		echo "stopping Zabbix agent"
		stop
		;;
	status)
		ps aux | grep [z]abbix_agentd
		;;
	reload)
		echo "reloading Zabbix agent configuration"
		kill -3 ${AGENTPID}
		;;
	restart)
		stop
		start
		;;
	*)
		echo "Illegal command: $1"
		cat <<- EOF
			usage:
			$0 {start|stop|status|reload|restart}
		EOF
		exit 101
		;;
esac
