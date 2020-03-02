#!/usr/bin/env bash

#### Constants ####

readonly version='1.0.0'

readonly code_type_py='py'
readonly code_type_node='node'

readonly fm_red="$(tput setaf 1)"
readonly fm_green="$(tput setaf 2)"
readonly fm_yellow="$(tput setaf 3)"
readonly fm_magenta="$(tput setaf 5)"
readonly fm_cyan="$(tput setaf 6)"
readonly fm_bold="$(tput bold)"
readonly fm_underline="$(tput smul)"
readonly fm_reset="$(tput sgr0)"

readonly style_command_title='cmd'
readonly stlye_error='err'

readonly env_var_venv_root='VENV_ROOT'
readonly env_var_ba_root='BA_ROOT'
readonly env_var_ba_node='BA_NODE_ROOT'
readonly env_var_kodiak_root='KODIAK_ROOT'
readonly env_var_om_root='OM_ROOT'
readonly env_var_ba_venv='BA_VENV'
readonly env_var_kodiak_venv='KODIAK_VENV'
readonly env_var_ba_nenv='BA_NENV'
readonly env_var_om_nenv='OM_NENV'
readonly env_var_ba_db='BA_DB'
readonly env_var_ba_celery_app='BA_CELERY_APP'
readonly env_var_tmux_lock_channel='TMUX_LOCK_CHANNEL'
readonly env_vars_required=( \
	"$env_var_venv_root" "$env_var_ba_root" "$env_var_ba_node" "$env_var_kodiak_root" "$env_var_om_root" "$env_var_ba_venv" \
	"$env_var_kodiak_venv" "$env_var_ba_nenv" "$env_var_om_nenv" "$env_var_ba_db" "$env_var_ba_celery_app" \
	"$env_var_tmux_lock_channel" \
)


readonly command_init='init'
readonly command_build='build'
readonly command_cleanup='cleanup'
readonly command_run='run'
readonly commands=( "$command_init" "$command_build" "$command_cleanup" "$command_run")

readonly option_help='--help'
readonly option_help_short='-h'
readonly option_version='--version'
readonly option_check='--check'
readonly option_verbose='--verbose'
readonly option_verbose_short='-v'
readonly allowed_options_base=( "$option_help" "$option_help_short" "$option_version" "$option_check" "$option_verbose" "$option_verbose_short")

readonly option_branch='--branch'
readonly option_branch_short='-b'
readonly run_command_allowed_options=( "$option_branch" "$option_branch_short" )

readonly message_usage="usage: om [$option_help|$option_help_short] [$option_version] [$option_verbose|$option_verbose_short] <command> [<args>]"
readonly message_usage_help="$message_usage

There are a number of possible commands:

	$command_init		Updates project for specified branches and saves a version of the database

			om $command_init <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]


	$command_build		Builds the origin markets stack with the specified branches

			om $command_build <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]


	$command_cleanup		Cleans up project to last time init was run

			om $command_cleanup [--last-snapshot|-ls]

	$command_run		Loads project environment and runs required command in it

			om $command_run <project> [$option_branch|$option_branch_short <branch>] <command> [<args>]

"
readonly message_check='Running environment check...'
readonly message_verbose='Verbose mode switched on'
readonly message_not_enough_args='Not enough arguments passed'
readonly message_incorrect_num_of_args='Incorrect number of arguments passed'
readonly message_unknown_project='Unknown project'

readonly project_ba='bankangle'
readonly project_ba_short='ba'
readonly project_ba_node='bankangle-node'
readonly project_ba_node_short='ba-node'
readonly project_om='om-elements'
readonly project_om_short='om'
readonly project_kod='kodiak'
readonly project_kod_short='kod'
readonly projects=( \
	"$project_ba" "$project_ba_short" \
	"$project_ba_node" "$project_ba_node_short" \
	"$project_om" "$project_om_short" \
	"$project_kod" "$project_kod_short" \
)


#### GLOBAL VARIABLES ####

verbose_mode='false'


#### FUNCTIONS ####

function get_dir() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$BA_ROOT"
			;;
		"$project_ba_node"|"$project_ba_node_short")
			printf "$BA_NODE_ROOT"
			;;
		"$project_om"|"$project_om_short")
			printf "$OM_ROOT"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$KODIAK_ROOT"
			;;
	esac

	return 0
}

function get_code_type() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$code_type_py"
			;;
		"$project_ba_node"|"$project_ba_node_short")
			printf "$code_type_node"
			;;
		"$project_om"|"$project_om_short")
			printf "$code_type_node"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$code_type_py"
			;;
	esac

	return 0
}

function get_code_env_name() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$BA_VENV"
			;;
		"$project_ba_node"|"$project_ba_node_short")
			printf "$BA_NENV"
			;;
		"$project_om"|"$project_om_short")
			printf "$OM_NENV"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$KODIAK_VENV"
			;;
	esac

	return 0
}

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
	is_in_array "$search" "${allowed_options_base[@]}"
}

function is_valid_command() {
	local search="$1"
	is_in_array "$search" "${commands[@]}"
}

function is_valid_project() {
	local search="$1"
	is_in_array "$search" "${projects[@]}"
}

function is_valid_run_command_option() {
	local search="$1"
	is_in_array "$search" "${[@]}"

}

function handle_base_options() {
	local option="$1"
	local command="$2"

	case "$option" in
		"$option_help" | "$option_help_short")
			printf "$message_usage_help\n"
			;;
		"$option_verbose" | "$option_verbose_short")
			printf "$message_verbose\n"
			verbose_mode='true'
			if [[ -z "$command" ]]; then
				printf "$message_not_enough_args\n\n"
				printf "$message_usage_help\n"
				return 1
			fi
			;;
		"$option_version")
			printf "$version\n"
			;;
		"$option_check")
			printf "$message_check\n"
			check_env 'true' || return 1
			;;
	esac

	return 0
}

function check_env() {
	local set_verbose="$1"
	local verbose='false'
	local vars_missing='false'

	if [[ "$verbose_mode" = 'true' ]] || ( [[ $# -ge 1 ]] && [[ "$set_verbose" = 'true' ]] ); then
		local verbose='true'
		printf "\n"
	fi

	for ev in "${env_vars_required[@]}"; do
		if [[ -z "${!ev+x}" ]]; then
			local vars_missing='true'
			printf "Checking '$ev'... ${fm_red}UNSET${fm_reset}\n"
		else
			if [[ "$verbose" = 'true' ]]; then
				printf "Checking '$ev'... ${fm_green}OK${fm_reset}\n"
			fi
		fi
	done

	if [[ "$vars_missing" = 'true' ]]; then
		printf "\n${fm_red}CHECK FAILED${fm_reset}\n"
		printf "Please set the ${fm_red}UNSET${fm_reset} environment variables above before running the program\n"
		return 1
	elif [[ "$verbose" = 'true' ]]; then
		printf "\n${fm_green}CHECK PASSED${fm_reset}\n"
	fi

	return 0
}

function print_format() {
	local type="$1"
	local msg="$2"

	case "$type" in
		"$style_command_title")
			printf "${fm_yellow}==>${fm_reset} $2\n"
			printf "%s\n" "------------------------------------------------------------" 
			;;
		"$style_error")
			printf "ERR! $2\n"
			;;
	esac

	return 0
}

function activate_code_env() {
	local code_type="$1"
	local env_name="$2"
	local run_install="$3"
	local title="Loading $code_type environment '$env_name'$([[ "$run_install" != 'true' ]] ||  printf ' (with package install)')"

	print_format "$style_command_title" "$title"

	#TODO: Figure out how to export this to the shell that called it
	source "$VENV_ROOT/$code_type/$env_name/bin/activate" || return 1

	if [[ "$run_install" = 'true'  ]]; then
		case "$code_type" in
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
	print_format "$style_command_title" "Changing directory to '$dir_name'"
	cd "$dir_name"
}

function checkout_git_branch() {
	local branch_name="$1"
	print_format "$style_command_title" "Checking out branch '$branch_name'"
	git fetch --all
	git checkout "$branch_name"
	git pull
}

function run_command() {
	print_format "$style_command_title" "Running command '$*'"
	$@
}

function run() {
	local project="$1"

	if [[ $# -lt 2 ]]; then
		print_format "$style_error" "$message_incorrect_num_of_args"
		return 1
	fi

	if [[ "$2" = "$option_branch" ]] || [[ "$2" = "$option_branch_short" ]]; then
		if [[ $# -lt 4 ]]; then
			print_format "$style_error" "$message_incorrect_num_of_args"
			return 1
		else
			local branch="$3"
			shift 3
		fi
	else
		shift
	fi

	if is_valid_project "$project"; then
		local project_dir="$(get_dir "$project")"
		local project_code_type="$(get_code_type "$project")"
		local project_code_env_name="$(get_code_env_name "$project")"

		change_dir "$project_dir" || return 1
		activate_code_env "$project_code_type" "$project_code_env_name" 'false' || return 1

		if [[ -n "$branch" ]]; then
			checkout_git_branch "$branch" || return 1
		fi

		run_command "$@" || return 1
	else
		print_format "$style_error" "$message_unknown_project: '$project'"
		return 1
	fi

	return 0
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
		"$command_run")
			run "$@" || return 1
			;;
	esac

	return 0
}


#### MAIN SCRIPT ####

if [[ $# -eq 0 ]]; then
	# Not enough arguments passed
	printf "$message_not_enough_args\n\n"
	printf "$message_usage_help\n"
	exit 1

elif is_valid_base_option "$1"; then
	# Command line option passed. Ignores all arguments after
	handle_base_options "$@" || exit 1
	exit 0

elif is_valid_command "$1"; then
	check_env || exit 1
	handle_command "$@" || exit 1
	exit 0

else
	printf "Unknown argument: $1\n"
	printf "$message_usage\n"
	exit 1

fi

