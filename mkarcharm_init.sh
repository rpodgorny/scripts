#!/bin/sh
set -e -x
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu --noconfirm --needed python
curl "https://raw.githubusercontent.com/rpodgorny/scripts/master/fix_system" >./fix_system.py
python ./fix_system.py
rm fix_system.py
