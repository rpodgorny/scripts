#!/bin/sh

# TODO: use return code of tty somehow - skip grep
if [ `/usr/bin/tty | grep dev` ]; then
	/usr/bin/emacs -nw $@
else
	/usr/bin/emacs $@
fi
