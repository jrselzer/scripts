#!/bin/bash
# Print top 10 most CPU consuming processes as CSV - if they consume at all
VERSION="0.1 20211017"
AUTHOR=jrselzer@github.com

TS="`date \"+%Y-%m-%d %H:%M:%S\"`"

ps aux | \
	sort -nrk 3,3 | \
	tail -n +2 | \
	head -10 | \
	while read -a a
	do 
		CPUP=${a[2]}
		if [ "${PCUP}" != "%CPU" ] && [ "${CPUP}" != "0.0" ]
		then
			L=$(($L +1))
			echo "\"${TS}\",\"${L}\",\"USR\",\"${a[0]}\",\"CPUP\",\"${CPUP}\",\"MEMP\",\"${a[3]}\",\"CMD\",\"${a[@]:10}\""
		fi
	done
