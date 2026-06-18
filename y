#!/bin/sh
set -e -x -o pipefail

populate_ssh_agent

# commented out because of some problem - i don't remember what was wrong
#niri-session
#dbus-run-session niri --session

# TODO: will this help with the gnome-portal? - answer: does not even start - cannot be launched directly
#systemctl --user start graphical-session.target
# TODO: lauch this manually to fix it
#/usr/lib/xdg-desktop-portal-gnome
niri --session
