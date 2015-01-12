#!/bin/bash

while read OLDNAME ; do
	SPLIT=`echo $OLDNAME | awk -F'-' '{ print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9}'`
	set -- $SPLIT
	PREFIX=$1
	IP=$2
	YEAR=$3
	MONTH=$4
	DAY=$5
	DOW=$6
	HOUR=$7
	MIN=$8
	SECandEXT=$9

	#IHST_233.17.33.205.50002_2011-09-27_2
	DAYDIR=${PREFIX}_${IP}_${YEAR}-${MONTH}-${DAY}_${DOW}

	#IHST_233.17.33.205.50002_2011-09-26_1_23-44-01.png
	NEWNAME=${PREFIX}_${IP}_${YEAR}-${MONTH}-${DAY}_${DOW}_${HOUR}-${MIN}-${SECandEXT}
	
	if [ ! -e ${DAYDIR} ] ; then
		echo -e "\n Creating ${DAYDIR}"
		mkdir ${DAYDIR}
	fi

	mv ${OLDNAME} ${DAYDIR}/${NEWNAME}
	echo -n "."
done
