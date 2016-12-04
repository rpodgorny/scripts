#!/bin/sh
set -e -x

#wget -r -l 1 --convert-links --page-requisites --no-parent -c --no-clobber $@
httrack -v -F Mozilla -r5 $@
