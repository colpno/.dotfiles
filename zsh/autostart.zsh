#!/bin/zsh
TODO_FILE="$HOME/.todo/todo.txt"

if [ -s TODO_FILE ]; then
	todo.sh ls
fi
