#!/bin/bash

BASEDIR=/var/www/vhosts/drupal/zabbix
PIDFILE=${BASEDIR}/zabbix_agentd.pid
AGENTPID=`cat ${PIDFILE}`

start() {
	[ ! -f ${PIDFILE} ] && ${BASEDIR}/sbin/zabbix_agentd -fc ${BASEDIR}/conf/zabbix_agentd.conf
}

stop() {
	kill ${AGENTPID}
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
