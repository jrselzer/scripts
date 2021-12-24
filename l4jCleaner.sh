#!/bin/bash
MYNAME=`basename $0 | cut -d. -f1`
VERSION="0.2 20211223"
AUTHOR=jrselzer@github.com
TARBALL=~/${MYNAME}_`date +%Y%m%d-%H%M%S`.tar
DETECTOR=log4j-detector-2021.12.22.jar
# This script needs https://github.com/mergebase/log4j-detector to run
# Detect JRE
for JRE in `locate --regex /bin/java$`
do
        ${JRE} > /dev/null 2>&1

        if [ $? -eq 0 ]
        then
                break;
        fi
done

# This function does the actual work. All the rest is just about finding the affected archive.
deleteClass() {
        ARCHIVE=$1

        CLASS=`unzip -l ${ARCHIVE} | grep JndiLookup.class | tr -s ' ' | cut -d ' ' -f5`
        zip -d ${ARCHIVE} ${CLASS}
}

# Run log4j-detector, find vulnerable files, unpack if neccessary and locate the archive that needs fixing
${JRE} -jar ${DETECTOR} / 2>/dev/null | \
        grep VULNERABLE | \
        while read JAR REST
        do
                # Backup Java Archive in case the manipulation fails
                tar rfv ${TARBALL} ${JAR%%\!*}

                # If the line contains at least one exclamation mark, the vulnerable class has not been found directly in the archive, but was packed inside an embedded archive
                if [[ "${JAR}" =~ "!" ]]
                then
                        IFS='!' read -ra part <<< ${JAR}
                        n=${#part[@]}
                        TMP=${MYNAME}_`date +%s`
                        mkdir ${TMP}
                        cd ${TMP}

                        # unpack and descend into extracted directory until the affected archive is found
                        for i in `seq 0 $((n - 2))`
                        do
#                               echo "$i ${part[$i]} ${part[$((i + 1))]}"
                                arch=${part[$i]}

                                if [ $i -gt 0 ]
                                then
                                        arch=`basename ${arch}`
                                fi

                                if [ $((i + 1)) -le $((n -1)) ]
                                then
                                        class=${part[$((i + 1))]}
                                        unzip ${arch} ${class#/}
                                        pushd .
                                        cd `dirname ${class#/}`
                                fi
                        done

                        deleteClass `basename ${class}`

                        # climb upwards in the directory tree and update the affected branch
                        while [ $i -ge 0 ]
                        do
                                arch=${part[$i]}
                                class=${part[$((i + 1))]}
                                popd

                                if [ $i -gt 0 ]
                                then
                                        arch=`basename ${arch}`
                                fi

                                zip -u ${arch} ${class#/}
                                i=$((i - 1))
                        done

                        # clean up
                        cd ..
                        rm -r ${TMP}
                else
                        deleteClass ${JAR}
                fi
        done
