#!/bin/sh
set -e -x -o pipefail

populate_ssh_agent
niri-session
