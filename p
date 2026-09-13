#!/bin/sh
# create/enter a project in ~/sync/projects and open a tmux session with claude
# (or a custom command: p <project> <command> [args...])

set -e

base="$HOME/sync/projects"
name="$1"

# dropped into every new project dir as AGENTS.md (+ CLAUDE.md/GEMINI.md symlinks)
instructions='- This directory is the whole project. Keep everything here.
- `MEMORY.md` here is your memory across sessions, in place of any tool-specific
  store. Read it first. Record what the files cannot show: decisions and why,
  dead ends, where external things live. Keep it pruned.
- A second tmux window sits idle in this directory. Run servers, watchers and
  tailed logs there so I can watch them: `tmux send-keys -t '"'"'{end}'"'"' '"'"'cmd'"'"' Enter`.'

[ -d "$base" ] || { echo "p: $base does not exist" >&2; exit 1; }
[ $# -ge 1 ] || { echo "p: usage: p <project> [command...]" >&2; exit 1; }
shift
[ $# -gt 0 ] || set -- claude --name "$name"  # default command

# also keeps the name usable as a tmux session name
case "$name" in
	''|-*|*[!A-Za-z0-9_-]*) echo "p: invalid project name: '$name'" >&2; exit 1 ;;
esac

if [ -d "$base/$name" ]; then
	echo "p: PROJECT ALREADY EXISTS: $name" >&2
else
	mkdir "$base/$name"
	printf '%s\n' "$instructions" > "$base/$name/AGENTS.md"
	ln -s AGENTS.md "$base/$name/CLAUDE.md"
	ln -s AGENTS.md "$base/$name/GEMINI.md"
fi

cd "$base/$name"

if ! tmux has-session -t "=$name" 2>/dev/null; then
	tmux new-session -d -s "$name" -c "$PWD" -- "$@"
	tmux new-window -t "=$name" -c "$PWD"
	tmux select-window -t "=$name:^"
fi

if [ -n "$TMUX" ]; then
	tmux switch-client -t "=$name"
	exit
fi

tmux attach-session -t "=$name"

# only when the session is really gone, not on detach
if ! tmux has-session -t "=$name" 2>/dev/null; then
	# a project holding only the generated instruction files counts as empty
	if [ "$(ls -A "$base/$name")" = "$(printf 'AGENTS.md\nCLAUDE.md\nGEMINI.md')" ]; then
		rm -f "$base/$name/AGENTS.md" "$base/$name/CLAUDE.md" "$base/$name/GEMINI.md"
	fi

	if rmdir "$base/$name" 2>/dev/null; then  # rmdir refuses non-empty
		echo "p: $name was empty, removed"
	else
		tree -a "$base/$name"
		echo
		echo "$base/$name"   # last line: easy to copy-paste into cd
	fi
fi
