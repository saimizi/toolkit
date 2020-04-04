#!/bin/bash

target=$*

if [ -z "$target" ];then
	echo "No document specified."
	exit
fi

for tgt in $target
do
	ntgt=`echo ${tgt} | sed "s/\..*$//"`

	echo -n "Compiling $tgt ..."

	platex -interaction=batchmode $tgt 1>/dev/null 2>&1
	platex -interaction=batchmode $tgt 1>/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "NG"
		cat ${ntgt}.log
		break;
	fi


	dvipdfmx ${ntgt}.dvi 1>>${tgt}.log 2>&1
	if [ $? -ne 0 ]; then
		echo "NG"
		echo "See ${tgt}.log ..."
		break;
	fi

	echo "OK"
	rm ${tgt}.log 2>/dev/null
	rm ${ntgt}.dvi 2>/dev/null
	rm ${ntgt}.aux 2>/dev/null
	rm ${ntgt}.log 2>/dev/null
	rm ${ntgt}.snm 2>/dev/null
	rm ${ntgt}.nav 2>/dev/null
	rm ${ntgt}.toc 2>/dev/null
	rm ${ntgt}.out 2>/dev/null
	evince ${ntgt}.pdf 2>/dev/null 1>&2 &
done

