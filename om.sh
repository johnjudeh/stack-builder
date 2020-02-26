#!/usr/bin/env bash

# Constants - TODO: Declare these as constants

version='1.0.0'
verbose_mode='false'

code_type_py='py'
code_type_node='node'

env_var_venv_root='VENV_ROOT'
env_var_ba_root='BA_ROOT'
env_var_ba_node='BA_NODE_ROOT'
env_var_kodiak_root='KODIAK_ROOT'
env_var_om_root='OM_ROOT'
env_var_ba_venv='BA_VENV'
env_var_kodiak_venv='KODIAK_VENV'
env_var_ba_nenv='BA_NENV'
env_var_om_nenv='OM_NENV'
env_var_ba_db='BA_DB'
env_var_ba_celery_app='BA_CELERY_APP'
env_var_tmux_lock_channel='TMUX_LOCK_CHANNEL'
env_vars_required=( \
	"$env_var_venv_root" "$env_var_ba_root" "$env_var_ba_node" "$env_var_kodiak_root" "$env_var_om_root" "$env_var_ba_venv" \
	"$env_var_kodiak_venv" "$env_var_ba_nenv" "$env_var_om_nenv" "$env_var_ba_db" "$env_var_ba_celery_app" \
	"$env_var_tmux_lock_channel" \
)


command_init='init'
command_build='build'
command_cleanup='cleanup'
commands=( "$command_init" "$command_build" "$command_cleanup" )

option_help='--help'
option_help_short='-h'
option_version='--version'
option_check='--check'
option_verbose='--verbose'
option_verbose_short='-v'
base_options=( "$option_help" "$option_help_short" "$option_version" "$option_check" "$option_verbose" "$option_verbose_short")

usage_message="usage: om [$option_help|$option_help_short] [$option_version] [$option_verbose|$option_verbose_short] <command> [<args>]"
usage_help_message="$usage_message

There are a number of possible commands:

	$command_init		Updates project for specified branches and saves a version of the database

			om $command_init <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]


	$command_build		Builds the origin markets stack with the specified branches

			om $command_build <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]


	$command_cleanup		Cleans up project to last time init was run

			om $command_cleanup [--last-snapshot|-ls]
"
check_message='Running environment check...'
verbose_message='Verbose mode switched on'
not_enough_args_message='Not enough arguments passed'

# Command Functions

function is_in_array() {
	local search="$1"
	local arr=("${@:2}")

	for val in "${arr[@]}"; do
		if [[ "$search" = "$val" ]]; then
			return 0
		fi
	done

	return 1
}

function is_valid_base_option() {
	local search="$1"
	is_in_array "$search" "${base_options[@]}"
}

function is_valid_command() {
	local search="$1"
	is_in_array "$search" "${commands[@]}"
}

function handle_base_options() {
	local option="$1"
	local command="$2"

	case "$option" in
		"$option_help" | "$option_help_short")
			printf "$usage_help_message\n"
			;;
		"$option_verbose" | "$option_verbose_short")
			printf "$verbose_message\n"
			verbose_mode='true'
			if [[ -z "$command" ]]; then
				printf "$not_enough_args_message\n\n"
				printf "$usage_help_message\n"
				return 1
			fi
			;;
		"$option_version")
			printf "$version\n"
			;;
		"$option_check")
			printf "$check_message\n"
			check_env 'true' || return 1
			;;
	esac

	return 0
}

function check_env() {
	local set_verbose="$1"
	local verbose='false'
	local vars_missing='false'

	if [[ "$verbose_mode" = 'true' ]] || ( [[ $# -eq 1 ]] && [[ "$set_verbose" = 'true' ]] ); then
		local verbose='true'
		printf "\n"
	fi

	for evn in "${env_vars_required[@]}"; do
		if [[ -z "${!evn}" ]]; then
			local vars_missing='true'
			printf "'$evn' is not set"
		else
			if [[ "$verbose" = 'true' ]]; then
				printf "$evn is set as: ${!evn}\n"
			fi
		fi
	done

	if [[ "$vars_missing" = 'true' ]]; then
		printf "The above environment variables must be set to run the program\n"
		return 1
	elif [[ "$verbose" = 'true' ]]; then
		printf "\nOK\n"
	fi

	return 0
}

function activate_code_env() {
	local code_type="$1"
	local env_name="$2"
	local run_install="$3"

	print_title "Loading $code_type environment '$env_name' (with$(if [[ "$run_install" = 'true' ]]; then; ; fi) package install)"

	source "$VENV_ROOT/$code_type/$env_name/bin/activate" || return 1

	if [[ "$run_install" = 'true'  ]]; then
		case "$code_type" in:
			"$code_type_py")
				pip install -r requirements.txt || return 1
				;;
			"$code_type_node")
				npm install || return 1
				git checkout -- package-lock.json || return 1
				;;
		esac
	fi

	return 0
}

function change_dir() {
	local dir_name="$1"
	print_title "Changing directory to '$dir_name'"
	cd "$dir_name"
}

function checkout_git_branch() {
	local branch_name="$1"
	print_title "Checking out branch '$branch_name'"
	git fetch --all
	git checkout "$branch_name"
	git pull
}

# TODO: Update this to print in the way I like
function print_title() {
	echo ""
	echo ""
	echo $1
	echo "====================================================="
}

function init() {
	echo 'In the init command'
	echo
	echo "Args passed: \$1: $1, \$2: $2, \$3: $3"
	return 0
}

function build() {
	echo 'In the build command'
	echo
	echo "Args passed: \$1: $1, \$2: $2, \$3: $3"
	return 0
}

function cleanup() {
	echo 'In the cleanup command'
	echo
	echo "Args passed: \$1: $1, \$2: $2, \$3: $3"
	return 0
}

function handle_command() {
	local command="$1"

	shift

	case "$command" in
		"$command_init")
			init "$@" || return 1
			;;
		"$command_build")
			build "$@" || return 1
			;;
		"$command_cleanup")
			cleanup "$@" || return 1
			;;
	esac

	return 0
}


# Main script

if [[ $# -eq 0 ]]; then
	# Not enough arguments passed
	printf "$not_enough_args_message\n\n"
	printf "$usage_help_message\n"
	exit 1

elif is_valid_base_option "$1" "${base_options[@]}"; then
	# Command line option passed. Ignores all arguments after
	handle_base_options "$@" || exit 1
	exit 0

elif is_valid_command "$1" "${commands[@]}"; then
	check_env || exit 1
	handle_command "$@" || exit 1
	exit 0

else
	printf "Unknown argument: $1\n"
	printf "$usage_message\n"
	exit 1

fi

