#!/bin/sh

name=$1

if [ "$name" ]; then
	args="-A -s $name"
fi

tmux new-session $args

# old code
#if [ "$name" ]; then
#	args_attach="-t $name"
#	args_new="-s $name"
#fi

#tmux attach $args_attach || tmux new-session $args_new
