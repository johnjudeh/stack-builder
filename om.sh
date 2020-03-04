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
readonly env_var_kodiak_db='KODIAK_DB'
readonly env_var_ba_celery_app='BA_CELERY_APP'
readonly env_var_tmux_lock_channel='TMUX_LOCK_CHANNEL'
readonly env_vars_required=( \
	"$env_var_venv_root" "$env_var_ba_root" "$env_var_ba_node" "$env_var_kodiak_root" "$env_var_om_root" "$env_var_ba_venv" \
	"$env_var_kodiak_venv" "$env_var_ba_nenv" "$env_var_om_nenv" "$env_var_ba_db" "$env_var_kodiak_db" "$env_var_ba_celery_app" \
	"$env_var_tmux_lock_channel" \
)

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

readonly command_freeze='freeze'
readonly command_restore='restore'
readonly command_build='build'
readonly command_run='run'
readonly commands=( "$command_freeze" "$command_restore" "$command_build" "$command_run" )

readonly option_help='--help'
readonly option_help_short='-h'
readonly option_version='--version'
readonly option_check='--check'
readonly option_verbose='--verbose'
readonly option_verbose_short='-v'
readonly allowed_options_base=( "$option_help" "$option_help_short" "$option_version" "$option_check" "$option_verbose" "$option_verbose_short")

readonly option_branch='--branch'
readonly option_branch_short='-b'
readonly option_delete='--delete'
readonly option_delete_short='-d'
readonly run_command_allowed_options=( "$option_branch" "$option_branch_short" )
readonly freeze_command_allowed_options=( "$option_branch" "$option_branch_short" )
readonly restore_command_allowed_options=( "$option_delete" "$option_delete_short" )

readonly freeze_command_default_branch='master'
readonly freeze_command_projects=( \
	"$project_ba" "$project_ba_short" \
	"$project_kod" "$project_kod_short" \
)

readonly message_usage="usage: om [$option_help|$option_help_short] [$option_version] [$option_verbose|$option_verbose_short] <command> [<args>]"
readonly message_usage_help="$message_usage

There are a number of possible commands:

	$command_freeze		Freeze database for project. Uses the master branch by default

			om $command_freeze <project> [$option_branch|$option_branch_short <branch>]

	$command_restore		Restores project database to last time the freeze command was run. Optionally
			removes clean database after successful restore

			om $command_restore <project> [$option_delete|$option_delete_short]

	$command_build		Builds the origin markets stack with the specified branches

			om $command_build <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]

	$command_run		Loads project environment and runs required command in it

			om $command_run <project> [$option_branch|$option_branch_short <branch>] <command> [<args>]

"
readonly message_check='Running environment check...'
readonly message_verbose='Verbose mode switched on'
readonly message_not_enough_args='Not enough arguments passed'
readonly message_unknown_arg='Unknown argument'
readonly message_incorrect_num_of_args='Incorrect number of arguments passed'
readonly message_unknown_project='Unknown project'
readonly message_command_does_not_support_project='This command does not support the project'
readonly message_db_does_not_exist='Database does not exist'

readonly clean_db_suffix='clean'


#### GLOBAL VARIABLES ####

verbose_mode='false'


#### MAPPING FUNCTIONS ####

function get_project_dir() {
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

function get_project_code_type() {
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

function get_project_code_env_name() {
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

function get_project_db_name() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$BA_DB"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$KODIAK_DB"
			;;
	esac

	return 0
}

function get_project_requires_load_termsheet_templates() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf 'true'
			;;
		"$project_kod"|"$project_kod_short")
			printf 'false'
			;;
	esac

	return 0
}


#### UTILITY FUNCTIONS ####

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

function is_valid_project_for_freeze_command() {
	local search="$1"
	is_in_array "$search" "${freeze_command_projects[@]}"
}

function is_valid_run_command_option() {
	local search="$1"
	is_in_array "$search" "${run_command_allowed_options[@]}"
}

function is_valid_freeze_command_option() {
	local search="$1"
	is_in_array "$search" "${freeze_command_allowed_options[@]}"
}

function is_valid_restore_command_option() {
	local search="$1"
	is_in_array "$search" "${restore_command_allowed_options[@]}"
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


#### BASE TASK FUNCTIONS ###

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
	git fetch --all || return 1
	git checkout "$branch_name" || return 1
	git pull || return 1
	return 0
}

function run_command() {
	print_format "$style_command_title" "Running command '$*'"
	$@
}

function create_clean_db() {
	local db_name="$1"
	local clean_db_name="${db_name}_${clean_db_suffix}"

	print_format "$style_command_title" "Creating clean copy of database '$db_name' as '$clean_db_name'"

	# Create clean copy of database, overwriting it if it already exists
	local base_db_exists="$( psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" )"
	local clean_db_exists="$( psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$clean_db_name'" )"

	if [[ "$base_db_exists" != "1" ]]; then
		print_format "$style_error" "$message_db_does_not_exist: '$db_name'"
		return 1
	fi

	if [[ "$clean_db_exists" = "1" ]]; then
		psql -c "
			DROP DATABASE \"$clean_db_name\";
		" || return 1
	fi

	psql -c "
		CREATE DATABASE \"$clean_db_name\" WITH TEMPLATE \"$db_name\";
	" || return 1

	return 0
}

function restore_from_clean_db() {
	local db_name="$1"
	local delete_clean_db="$2"
	local clean_db_name="${db_name}_${clean_db_suffix}"

	print_format "$style_command_title" "Restoring database '$db_name' from '$clean_db_name'"

	local base_db_exists="$( psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" )"
	local clean_db_exists="$( psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$clean_db_name'" )"

	if [[ "$clean_db_exists" != '1' ]]; then
		print_format "$style_error" "$message_db_does_not_exist: '$clean_db_name'"
		return 1
	fi

	# Stop processes connected to db quickly
	psql -c "
		SELECT pg_terminate_backend(pg_stat_activity.pid)
		FROM pg_stat_activity
		WHERE pg_stat_activity.datname = '$db_name'
		AND pid <> pg_backend_pid();
	" || return 1

	# Drop altered db
	if [[ "$base_db_exists" = '1'  ]]; then
		psql -c "
			DROP DATABASE \"$db_name\";
		" || return 1
	fi

	# Restore clean database to old name
	psql -c "
		CREATE DATABASE \"$db_name\" WITH TEMPLATE \"$clean_db_name\";
	" || return 1

	# Drop clean db if flag is set
	if [ "$delete_clean_db" = 'true' ]; then
		print_format "$style_command_title" "Deleting clean database '$clean_db_name' after successful restore"
		psql -c "
			DROP DATABASE \"$clean_db_name\";
		" || return 1
	fi

	return 0
}

function django_migrate_db() {
	print_format "$style_command_title" 'Django migrate database'
	python manage.py migrate
}

function load_termsheet_templates() {
	print_format "$style_command_title" 'Loading termsheet templates'
	python manage.py load_termsheet_templates --noinput
}


#### COMMAND-SPECIFIC FUNCTIONS ####

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
		print_format "$style_command_title" "$message_check"
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

function freeze() {
	local project="$1"

	if [[ $# -eq 0 ]]; then
		print_format "$style_error" "$message_not_enough_args"
		return 1
	fi

	if [[ $# -ge 2 ]]; then
		if is_valid_freeze_command_option "$2"; then
			local option="$2"

			case "$option" in
				"$option_branch"|"$option_branch_short")
					if [[ $# -ne 3 ]]; then
						print_format "$style_error" "$message_incorrect_num_of_args"
						return 1
					else
						local branch="$3"
					fi
					;;
			esac
		else
			print_format "$style_rror" "$message_unknown_arg: $2"
			printf "$message_usage\n"
			return 1
		fi
	else
		local branch="$freeze_command_default_branch"
	fi

	if is_valid_project_for_freeze_command "$project"; then
		local project_dir="$(get_project_dir "$project")"
		local project_code_type="$(get_project_code_type "$project")"
		local project_code_env_name="$(get_project_code_env_name "$project")"
		local project_requires_load_termsheet_templates=$(get_project_requires_load_termsheet_templates "$project")
		local project_db_name="$(get_project_db_name "$project")"

		change_dir "$project_dir" || return 1

		if [[ -n "$branch" ]]; then
			checkout_git_branch "$branch" || return 1
		fi

		activate_code_env "$project_code_type" "$project_code_env_name" 'true' || return 1
		django_migrate_db

		if [[ "$project_requires_load_termsheet_templates" = 'true' ]]; then
			load_termsheet_templates
		fi

		create_clean_db "$project_db_name"

	elif is_valid_project "$project"; then
		print_format "$style_error" "$message_command_does_not_support_project: '$project'"
		return 1

	else
		print_format "$style_error" "$message_unknown_project: '$project'"
		return 1
	fi

	return 0
}

function restore() {
	local project="$1"
	local delete_db='false'

	if [[ $# -eq 0 ]]; then
		print_format "$style_error" "$message_not_enough_args"
		return 1
	fi

	if [[ $# -ge 2 ]]; then
		if is_valid_restore_command_option "$2"; then
			local option="$2"

			case "$option" in
				"$option_delete"|"$option_delete_short")
					local delete_db='true'
					;;
			esac
		else
			print_format "$style_rror" "$message_unknown_arg: $2"
			printf "$message_usage\n"
			return 1
		fi
	fi

	if is_valid_project_for_freeze_command "$project"; then
		local project_db_name="$(get_project_db_name "$project")"
		restore_from_clean_db "$project_db_name" "$delete_db"

	elif is_valid_project "$project"; then
		print_format "$style_error" "$message_command_does_not_support_project: '$project'"
		return 1

	else
		print_format "$style_error" "$message_unknown_project: '$project'"
		return 1
	fi

	return 0
}

function run() {
	local project="$1"

	if [[ $# -lt 2 ]]; then
		print_format "$style_error" "$message_incorrect_num_of_args"
		return 1
	fi

	if is_valid_run_command_option "$2"; then
		local option="$2"

		case "$option" in
			"$option_branch"|"$option_branch_short")
				if [[ $# -lt 4 ]]; then
					print_format "$style_error" "$message_incorrect_num_of_args"
					return 1
				else
					local branch="$3"
					shift 3
				fi
				;;
		esac
	else
		shift
	fi

	if is_valid_project "$project"; then
		local project_dir="$(get_project_dir "$project")"
		local project_code_type="$(get_project_code_type "$project")"
		local project_code_env_name="$(get_project_code_env_name "$project")"

		change_dir "$project_dir" || return 1

		if [[ -n "$branch" ]]; then
			checkout_git_branch "$branch" || return 1
		fi

		activate_code_env "$project_code_type" "$project_code_env_name" 'false' || return 1

		run_command "$@" || return 1
	else
		print_format "$style_error" "$message_unknown_project: '$project'"
		return 1
	fi

	return 0
}

function build() {
	echo 'In the build command'
	echo
	echo "Args passed: \$1: $1, \$2: $2, \$3: $3"
	return 0
}

function handle_command() {
	local command="$1"

	shift

	case "$command" in
		"$command_freeze")
			freeze "$@" || return 1
			;;
		"$command_restore")
			restore "$@" || return 1
			;;
		"$command_build")
			build "$@" || return 1
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

else
	for arg in "$@"; do
		if is_valid_base_option "$arg"; then
			# Command line option passed. Ignores all arguments after
			handle_base_options "$@" || exit 1
			shift

		elif is_valid_command "$arg"; then
			check_env || exit 1
			handle_command "$@" || exit 1
			exit 0

		else
			printf "Unknown argument: $1\n"
			printf "$message_usage\n"
			exit 1
		fi
	done
fi

