#!/bin/sh
# create/enter a project in ~/sync/projects and open a tmux session with claude
# (or a custom command: p <project> <command> [args...])

set -e

base="$HOME/sync/projects"
name="$1"

[ -d "$base" ] || { echo "p: $base does not exist" >&2; exit 1; }
[ $# -ge 1 ] || { echo "p: usage: p <project> [command...]" >&2; exit 1; }
shift
[ $# -gt 0 ] || set -- claude --name "$name"  # default command

case "$name" in
	''|*/*|.|..) echo "p: invalid project name: '$name'" >&2; exit 1 ;;
esac

if [ -d "$base/$name" ]; then
	echo "p: PROJECT ALREADY EXISTS: $name" >&2
else
	mkdir "$base/$name"
fi

cd "$base/$name"

# tmux forbids . and : in session names
session=$(echo "$name" | tr '.:' '__')

if ! tmux has-session -t "=$session" 2>/dev/null; then
	tmux new-session -d -s "$session" -c "$PWD" -- "$@"
	tmux new-window -t "=$session" -c "$PWD"
	tmux select-window -t "=$session:^"
fi

if [ -n "$TMUX" ]; then
	tmux switch-client -t "=$session"
	exit
fi

tmux attach-session -t "=$session"

# only when the session is really gone, not on detach
if ! tmux has-session -t "=$session" 2>/dev/null; then
	if rmdir "$base/$name" 2>/dev/null; then  # rmdir refuses non-empty
		echo "p: $name was empty, removed"
	else
		tree -a "$base/$name"
		echo
		echo "$base/$name"   # last line: easy to copy-paste into cd
	fi
fi
