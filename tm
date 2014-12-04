#!/bin/sh

name=$1

# this works but when executed without name, it creates new session
#if [ "$name" ]; then
#	args="-A -s $name"
#fi
#tmux new-session $args

# this creates new session or attaches to existing one
# when executed with name but default to creating/attaching
# to session 0
if [ "$name" ]; then
	args_attach="-t $name"
	args_new="-s $name"
fi
tmux attach $args_attach || tmux new-session $args_new
