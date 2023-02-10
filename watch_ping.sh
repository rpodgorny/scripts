#!/bin/bash
set -e -x

HOST=$1

test -n "${HOST}"

while true; do
	DT=`date --iso-8601=seconds`
	PING=`ping -w 10 -4 ${HOST} | grep rtt`
	echo "${DT} ${PING}"
	sleep 60
done;
