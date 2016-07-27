#!/bin/sh
set -e -x

PORT=$1
/usr/bin/socat TCP6-LISTEN:$PORT,reuseaddr,ipv6only TCP4:127.0.0.1:$PORT
