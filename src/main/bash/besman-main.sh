#!/usr/bin/bash

function bes() {
	local environment playbook version subcommand variable value command opt
	[[ -z $1 ]] && __bes_help && return 1
	while getopts ":e: v: p: r" opt; do
		echo "opt:$opt"
		case $opt in
		e)
			environment=$OPTARG
			;;
		p)
			playbook=$OPTARG
			;;
		v)
			echo "optarg:$OPTARG"
			if [[ -z "$OPTARG" ]]; then
				version=""
			else
				version=$OPTARG
			fi
			;;
		\?)
			__besman_echo_red "Invalid option: -$OPTARG"
			;;
		esac

	done
	[[ -z $command ]] && command=$1

	# commands_list=(install uninstall update validate reset list help rm upgrade create set pull run status)
	echo "command:$1"
	echo "command_var:$command"
	case $command in
	install | uninstall | create | run | update | validate | reset)
		__bes_"$command" "$environment" "$version"
		;;
	list)
		__bes_"$command" "$2"
		;;
	help)
		subcommand=$2
		[[ -z "$subcommand" ]] && __bes_help && return 0
		__bes_"$command" "$subcommand"
		;;
	status | upgrade | remove)
		__bes_"$command"
		;;
	set)
		variable=$1
		value=$2
		;;

	esac
	unset environment playbook version subcommand variable value command opt
}
