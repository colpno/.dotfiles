#!/bin/zsh
TODO_FILE="$HOME/.todo/todo.txt"

if [ -e $TODO_FILE ]; then
	if [ -s $TODO_FILE ]; then
		   todo.sh ls
	fi
else
	echo "$TODO_FILE doesn't exist"
fi
