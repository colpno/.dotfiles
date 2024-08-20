#!/bin/zsh
TODO_FILE="$HOME/.todo/todo.txt"

if [[ -e "$TODO_FILE" && -s "$TODO_FILE" ]]; then
	todo.sh ls
fi
