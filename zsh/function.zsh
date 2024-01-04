open_terminal_run_command() {
	gnome-terminal --tab --title="$1" -- bash -c "$2"
}

run_project() {
	if [[ $# -eq 1 ]]; then
		case $1 in
			FavVid)
				server_title='Backend'
				server_dir='~/Workspace/FavVid/server'
				server_run_command='npm run dev'

				client_title='Frontend'
				client_dir='~/Workspace/FavVid/client'
				client_run_command='npm run dev'

				if [[ $1 == 'server' ]]; then
					open_terminal_run_command $server_title "cd $server_dir && code . && $server_run_command"
				else
					open_terminal_run_command $server_title "cd $server_dir && $server_run_command"
				fi

				if [[ $1 == 'client' ]]; then
					open_terminal_run_command $client_title "cd $client_dir && code . && $client_run_command"
				else
					open_terminal_run_command $client_title "cd $client_dir && code . && $client_run_command"
				fi
				;;
			*)
				echo 'Unknown project name'
				;;
		esac
	else
		echo 'The project name must be pass as the first argument'
	fi
}
