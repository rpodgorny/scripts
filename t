#!/bin/sh

FONT="-*-terminus-medium-*-*-*-14-*-*-*-*-*-*-u"
#FONT="-*-terminus-medium-*-*-*-14-*-*-*-*-*-iso10646-1"

#exec /usr/bin/xterm -rv -vb +sb -fn ${FONT} -xrm "XTerm*charClass: 0-32:1,33-126:2,127-160:3,161-255:2"

exec /usr/bin/st -f ${FONT}

#urxvtc -rv -vb +sb -fn ${FONT} -fb ${FONT}
#if [ $? -eq 2 ]; then
#	urxvtd -q -o -f
#	urxvtc -rv -vb +sb -fn ${FONT} -fb ${FONT}
#fi
