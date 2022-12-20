#!/bin/bash

while true; do
	DT=`date --iso-8601=seconds`
	PING=`ping -w 10 -4 www.seznam.cz | grep rtt`
	echo "${DT} ${PING}"
	sleep 60
done;
