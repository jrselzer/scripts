#!/bin/bash
MYNAME=`basename $0 | cut -d. -f1`
TIMESTAMP=`date +%Y%m%d%H%M%S`
VERSION="0.4.1 20211231"
AUTHOR=jrselzer@github.com
DETECTORSCRIPT=log4j-detector-2021.12.29.jar
WRAPPER=l4jDetectorWrapper
SERVERLIST=serverlist.txt
# serverlist is a textfile containing entries for servers and users like
# server_1 user_11 user_12 ... user_1n
# server_2 user_21
# ...
# server_n user_n1 user_n2
#NSERVER=`wc -l ${SERVERLIST} | cut -d' ' -f1`
NSERVER=0
NCOMPLETED=0
COMPLETED=serverlist_completed.txt
WAITFOR=300

# Write a message with a timestamp onto the screen and into a file
log() {
        echo "`date \"+%Y-%m-%d %H:%M:%S\"` $1" | tee -a ${MYNAME}.log
}

# Copy detector script onto a server and start it
scanServer() {
        server=$1
        user=${2:-root}

        # place current l4j-Detector.jar in the script
        sed -e 's/DETECTORSCRIPT/'${DETECTORSCRIPT}'/' ${WRAPPER}.template > ${WRAPPER}.sh
        chmod u+x ${WRAPPER}.sh
        log "## Copying scripts to ${user}@${server}"
        scp /pubscratch/${DETECTORSCRIPT} ${user}@${server}: 2>/dev/null
        scp ${WRAPPER}.sh ${user}@${server}: 2>/dev/null
        log "### Scanning ${server}"
        ssh -tn ${user}@${server} "chmod u+x ./${WRAPPER}.sh; nohup ./${WRAPPER}.sh >/dev/null 2>&1 &" 2>/dev/null
}

if [ -n "$1" ]
then
        scanServer $1 $2
else
        while read server userlist
        do
                for user in ${userlist:-root}
                do
                        NSERVER=$((NSERVER + 1))
                        scanServer ${server} ${user}
                done
        done < ${SERVERLIST}
fi

cat /dev/null > ${COMPLETED}

while true
do
        while read server userlist
        do
                for user in ${userlist:-root}
                do
                        if [ `grep -c "${user}@${server}" ${COMPLETED}` -eq 0 ]
                        then
                                log "looking for results on ${server}"

                                RESULT=`swrap -tn ${user:-root}@${server} \
                                        "if [ -f ${WRAPPER}.tmp ]; \
                                        then \
                                                echo 'STILL WORKING'; \
                                        elif [ -f ${WRAPPER}.log ]; \
                                        then \
                                                cat ${WRAPPER}.log; \
                                        else \
                                                echo 'NO RESULTS'; \
                                        fi" 2>/dev/null`

                                if [ -z "${RESULT}" ] || [ "${RESULT}" = "NO RESULTS" ]
                                then
                                        echo "${server};NOTHING TO WORRY" | \
                                                tee -a ${MYNAME}_${TIMESTAMP}.log
                                        echo "${user}@${server}" >> ${COMPLETED}
                                elif [ "${RESULT}" != "STILL WORKING" ]
                                then
                                        echo "${RESULT}" | \
                                                tee -a ${MYNAME}_${TIMESTAMP}.log
                                        # if there are multiple scans running on the same server, delete duplicate lines
                                        if [[ "${userlist}" =~ " " ]]
                                        then
                                                awk '{if (count[$0] == 0){print $0; count[$0]++}}' ${MYNAME}_${TIMESTAMP}.log > ${MYNAME}_${TIMESTAMP}.tmp
                                                mv ${MYNAME}_${TIMESTAMP}.tmp ${MYNAME}_${TIMESTAMP}.log
                                        fi

                                        echo "${user}@${server}" >> ${COMPLETED}
                                else
                                        echo "${RESULT}"
                                fi
                        fi
                done
        done < ${SERVERLIST}

        NCOMPLETED=`wc -l ${COMPLETED} | cut -d' ' -f1`

        if [ ${NCOMPLETED} -lt ${NSERVER} ]
        then
                echo "missing:"

                while read server userlist
                do
                        for user in ${userlist:-root}
                        do
                                [ `grep -c "${user}@${server}" ${COMPLETED}` -gt 0 ] || \
                                        echo "${user}@${server}"
                        done
                done < ${SERVERLIST}

                log "waiting ${WAITFOR} seconds"
                sleep ${WAITFOR}
        else
                break
        fi
done
