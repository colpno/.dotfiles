open_terminal_run_command() {
	gnome-terminal --tab --title="$1" -- bash -c "$2"
}

compare_insensitive() {
	var1=$(echo $1 | tr '[:upper:]' '[:lower:]')
	var2=$(echo $2 | tr '[:upper:]' '[:lower:]')

	if [ "$var1" = "$var2" ]; then
		return 0
	else
		return 1
	fi
}

run_project() {
	WORKSPACE="~/Workspace"
	SERVER_TITLE="Server"
	CLIENT_TITLE="Client"
	ADMIN_TITLE="Admin"

	if [[ $# -ge 1 ]]; then
		project=$(echo $1 | tr '[:upper:]' '[:lower:]')

		case $project in
			movie)
				ROOT_DIR="$WORKSPACE/movie-app"

				SERVER_DIR="$ROOT_DIR/server"
				SERVER_RUN_COMMAND="php '/home/vinh/Workspace/movie-app/server/artisan' serve --host=localhost --port=8000"

				CLIENT_DIR="$ROOT_DIR/client"
				CLIENT_RUN_COMMAND="npm run dev"

				open_terminal_run_command $SERVER_TITLE "cd $SERVER_DIR && $SERVER_RUN_COMMAND"
				open_terminal_run_command $CLIENT_TITLE "cd $CLIENT_DIR && $CLIENT_RUN_COMMAND"
				;;
			favvid)
				ROOT_DIR="$WORKSPACE/FavVid"

				SERVER_DIR="$ROOT_DIR/server"
				SERVER_RUN_COMMAND="npm run dev"

				CLIENT_DIR="$ROOT_DIR/client"
				CLIENT_RUN_COMMAND="npm run dev"

				open_terminal_run_command $SERVER_TITLE "cd $SERVER_DIR && $SERVER_RUN_COMMAND"
				open_terminal_run_command $CLIENT_TITLE "cd $CLIENT_DIR && $CLIENT_RUN_COMMAND"
				;;
			comic)
				ROOT_DIR="$WORKSPACE/MongoERN_Comic"

				SERVER_DIR="$ROOT_DIR/server"
				SERVER_RUN_COMMAND="npm start"

				CLIENT_DIR="$ROOT_DIR/client"
				CLIENT_RUN_COMMAND="npm start"

				ADMIN_DIR="$ROOT_DIR/admin"
				ADMIN_RUN_COMMAND="npm start"

				echo -n "client or admin or both: "
				read opt_comic
				open_terminal_run_command $SERVER_TITLE "cd $SERVER_DIR && $SERVER_RUN_COMMAND"
				if compare_insensitive $opt_comic "client" || compare_insensitive $opt_comic "both" ; then
					open_terminal_run_command $CLIENT_TITLE "cd $CLIENT_DIR && $CLIENT_RUN_COMMAND"
				fi
				if compare_insensitive $opt_comic "admin" || compare_insensitive $opt_comic "both" ; then
					open_terminal_run_command $ADMIN_TITLE "cd $ADMIN_DIR && $ADMIN_RUN_COMMAND"
				fi
				;;
			*)
				echo "Unknown project name"
				;;
		esac
	else
		echo "The project name must be pass as the first argument"
	fi
}

mongo_runner() {
    case "$1" in
        --start)
            sudo service mongod start
            ;;
        --stop)
            sudo service mongod stop
            ;;
        --restart)
            sudo service mongod restart
            ;;
		--status)
			sudo systemctl status mongod
			;;
        *)
            echo "Invalid usage. Usage: mongo --start | --stop | --restart | --status"
            return 1
            ;;
    esac
}
