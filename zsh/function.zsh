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
	if [[ $# -ge 1 ]]; then
		case $1 in
			FavVid)
				SERVER_TITLE="Server"
				SERVER_DIR="$WORKSPACE/FavVid/server"
				SERVER_RUN_COMMAND="npm run dev"

				CLIENT_TITLE="Client"
				CLIENT_DIR="$WORKSPACE/FavVid/client"
				CLIENT_RUN_COMMAND="npm run dev"

				open_terminal_run_command $SERVER_TITLE "cd $SERVER_DIR && $SERVER_RUN_COMMAND"
				open_terminal_run_command $CLIENT_TITLE "cd $CLIENT_DIR && $CLIENT_RUN_COMMAND"
				;;
			Comic)
				SERVER_TITLE="Server"
				SERVER_DIR="$WORKSPACE/MongoERN_Comic/server"
				SERVER_RUN_COMMAND="npm start"

				CLIENT_TITLE="Client"
				CLIENT_DIR="$WORKSPACE/MongoERN_Comic/client"
				CLIENT_RUN_COMMAND="npm start"

				ADMIN_TITLE="Admin"
				ADMIN_DIR="$WORKSPACE/MongoERN_Comic/admin"
				ADMIN_RUN_COMMAND="npm start"

				echo -n "client or admin or both: "
				read opt_comic
				open_terminal_run_command $SERVER_TITLE "cd $SERVER_DIR && $SERVER_RUN_COMMAND"
				if compare_insensitive $opt_comic "client" || compare_insensitive $opt_comic "both" ; then
					open_terminal_run_command $CLIENT_TITLE "cd $CLIENT_DIR && $CLIENT_RUN_COMMAND"
				fi
				if compare_insensitive $opt_comic "server" || compare_insensitive $opt_comic "both" ; then
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
