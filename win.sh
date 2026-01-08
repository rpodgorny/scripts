#!/bin/sh
set -e -x

IMG=win.img

cd ~/tmp/win
#qemu-img create -f raw $IMG 16G
exec qemu-system-x86_64 -enable-kvm -cpu host -smp cores=2 -m 2000 -hda $IMG -net nic -net user,smb=/ -usbdevice tablet "$@"
