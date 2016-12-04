#!/bin/sh
set -e -x

PORT=$1
/usr/bin/socat -d -d TCP6-LISTEN:$PORT,reuseaddr,ipv6only,fork TCP4:127.0.0.1:$PORT
