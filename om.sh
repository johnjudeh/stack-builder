#!/usr/bin/env bash

######## Constants ########

readonly script_name='om'
readonly version='1.0.0'

readonly virtual_env_type_py='py'
readonly virtual_env_type_node='node'
readonly project_type_django='django'
readonly project_type_node='node'

readonly fm_red="$(tput setaf 1)"
readonly fm_green="$(tput setaf 2)"
readonly fm_yellow="$(tput setaf 3)"
readonly fm_magenta="$(tput setaf 5)"
readonly fm_cyan="$(tput setaf 6)"
readonly fm_bold="$(tput bold)"
readonly fm_underline="$(tput smul)"
readonly fm_reset="$(tput sgr0)"

readonly style_command_title='cmd'
readonly style_error='err'

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

readonly port_ba='8000'
readonly port_kod='8002'

readonly command_freeze='freeze'
readonly command_restore='restore'
readonly command_build='build'
readonly command_run='run'
readonly command_scipt_run='script-run'
readonly commands=( "$command_freeze" "$command_restore" "$command_build" "$command_run" "$command_scipt_run" )

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
readonly option_om='--om'
readonly option_om_short='-o'
readonly option_kod='--kod'
readonly option_kod_short='-k'
readonly freeze_command_allowed_options=( "$option_branch" "$option_branch_short" )
readonly restore_command_allowed_options=( "$option_delete" "$option_delete_short" )
readonly build_command_allowed_options=( "$option_om" "$option_om_short" "$option_kod" "$option_kod_short" )
readonly run_command_allowed_options=( "$option_branch" "$option_branch_short" )

readonly freeze_command_default_branch='master'
readonly freeze_command_projects=( \
	"$project_ba" "$project_ba_short" \
	"$project_kod" "$project_kod_short" \
)

readonly build_command_project_tags=( \
	"$project_ba_short" "$project_om_short" "$project_kod_short" \
)

readonly message_usage="usage: $script_name [$option_help|$option_help_short] [$option_version] [$option_verbose|$option_verbose_short] [$option_check] <command> [<args>]"
readonly message_usage_help="$message_usage

There are a number of possible commands:

	$command_freeze		Freeze database for project. Uses the master branch by default

			$script_name $command_freeze <project> [$option_branch|$option_branch_short <branch>]

	$command_restore		Restores project database to last time the freeze command was run. Optionally
			removes clean database after successful restore

			$script_name $command_restore <project> [$option_delete|$option_delete_short]

	$command_build		Builds each specified project and its dependant services with the specified
			branches

			$script_name $command_build <ba-branch> [$option_om|$option_om_short <om-branch>] [$option_kod|$option_kod_short <kodiaik-branch>]

	$command_run		Loads project environment and runs required command in it

			$script_name $command_run <project> [$option_branch|$option_branch_short <branch>] <command> [<args>]
"
readonly message_check='Running environment check...'
readonly message_verbose='Verbose mode switched on'
readonly message_not_enough_args='Not enough arguments passed'
readonly message_unknown_arg='Unknown argument'
readonly message_incorrect_num_of_args='Incorrect number of arguments passed'
readonly message_unknown_project='Unknown project'
readonly message_command_does_not_support_project='This command does not support the project'
readonly message_db_does_not_exist='Database does not exist'
readonly message_multiple_running_tmux_sessions='Multiple running tmux sessions'
readonly message_function_returned_error='Function returned non-zero value'

readonly clean_db_suffix='clean'
readonly tmux_default_lock_channel='lock'
readonly tmux_default_window_name='orchestrator'
readonly tmux_win_name_django_suffix='_django'
readonly tmux_win_name_celery_suffix='_celery'
readonly tmux_win_name_npm_watch_suffix='_npm_w'
readonly sesh_name_sep=';'
readonly sesh_name_regex="^${script_name}(${sesh_name_sep}($project_ba_short)=([0-9A-z_\-\/]+))?(${sesh_name_sep}($project_om_short)=([0-9A-z_\-\/]+))?(${sesh_name_sep}($project_kod_short)=([0-9A-z_\-\/]+))?$"

readonly file_pattern_py_requirments='*requirements*'
readonly file_pattern_node_requirements='*package.json*'
readonly file_pattern_django_migrations='*migrations*'
readonly file_pattern_ts_templates='*fixtures/termsheet_templates*'


######## GLOBAL VARIABLES ########

verbose_mode='false'


######## MAPPING FUNCTIONS ########

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

function get_project_virtual_env_type() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$virtual_env_type_py"
			;;
		"$project_ba_node"|"$project_ba_node_short")
			printf "$virtual_env_type_node"
			;;
		"$project_om"|"$project_om_short")
			printf "$virtual_env_type_node"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$virtual_env_type_py"
			;;
	esac

	return 0
}

function get_project_virtual_env_name() {
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

function get_project_type() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$project_type_django"
			;;
		"$project_ba_node"|"$project_ba_node_short")
			printf "$project_type_node"
			;;
		"$project_om"|"$project_om_short")
			printf "$project_type_node"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$project_type_django"
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

function get_project_port() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$port_ba"
			;;
		"$project_kod"|"$project_kod_short")
			printf "$port_kod"
			;;
	esac

	return 0
}

function get_project_celery_app_name() {
	local project="$1"

	case "$project" in
		"$project_ba"|"$project_ba_short")
			printf "$BA_CELERY_APP"
			;;
	esac

	return 0
}



######## UTILITY FUNCTIONS ########

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

function is_valid_project_tag_for_build_command() {
	local search="$1"
	is_in_array "$search" "${build_command_project_tags[@]}"
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

function is_valid_build_command_option() {
	local search="$1"
	is_in_array "$search" "${build_command_allowed_options[@]}"
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
			printf "${fm_red}ERR!${fm_reset} $2\n" 1>&2
			;;
	esac

	return 0
}


######## BASE TASK FUNCTIONS ########

function activate_code_env() {
	local code_type="$1"
	local env_name="$2"
	local run_install="$3"
	local title="Loading $code_type environment '$env_name'$([[ "$run_install" != 'true' ]] ||  printf ' (with package install)')"

	print_format "$style_command_title" "$title"

	# TODO: Figure out how to export this to the shell that called it
	source "$VENV_ROOT/$code_type/$env_name/bin/activate" || return 1

	if [[ "$run_install" = 'true'  ]]; then
		case "$code_type" in
			"$virtual_env_type_py")
				pip install -r requirements.txt || return 1
				;;
			"$virtual_env_type_node")
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

function django_start_server() {
	local port="$1"
	print_format "$style_command_title" "Starting django server on port '$port'"
	python manage.py runserver "$port"
}

function django_start_celery() {
	local app_name="$1"
	local priority="$2"

	print_format "$style_command_title" "Starting '$app_name' celery worker $([[ -z "$priority" ]] || printf "%s" "($priority)")"

	if [[ -n "$priority" ]]; then
		celery -A "$app_name" worker -Q "$priority"
	else
		celery -A "$app_name" worker
	fi
}

function npm_run_watch() {
	print_format "$style_command_title" 'Starting npm watch'
	npm run watch
}

function goto_project() {
	local porject="$1"
	local run_install="$2"
	local branch="$3"
	local project_dir="$(get_project_dir "$project")"
	local project_code_type="$(get_project_virtual_env_type "$project")"
	local project_code_env_name="$(get_project_virtual_env_name "$project")"

	change_dir "$project_dir" || return 1

	if [[ -n "$branch" ]]; then
		checkout_git_branch "$branch" || return 1
	fi

	activate_code_env "$project_code_type" "$project_code_env_name" "$run_install" || return 1

	return 0
}

function setup_project_branch() {
	local project="$1"
	local run_install="$2"
	local branch="$3"
	# TODO: Potentially rethink these args as they are django-specific parameters
	local run_migrations="$4"
	local load_ts_templates="$5"
	local project_type="$(get_project_type "$project")"

	goto_project "$project" "$run_install" "$branch" || return 1

	if [[ "$project_type" = "$project_type_django" ]]; then
		local project_requires_load_termsheet_templates=$(get_project_requires_load_termsheet_templates "$project")

		if [[ "$run_migrations" = 'true' ]]; then
			django_migrate_db || return 1
		fi

		if [[ "$project_requires_load_termsheet_templates" = 'true' && "$load_ts_templates" = 'true'  ]]; then
			load_termsheet_templates || return 1
		fi
	fi

	return 0
}

function run_django_start_server() {
	local project="$1"
	local port="$2"

	goto_project "$project" 'false' || return 1
	django_start_server "$port"
}

function run_django_start_celery() {
	local project="$1"
	local app_name="$2"
	local priority="$3"

	goto_project "$project" 'false' || return 1
	django_start_celery "$app_name" "$priority"
}

function run_npm_run_watch() {
	local project="$1"

	goto_project "$project" 'false' || return 1
	npm_run_watch
}


function run_command_with_tmux_unlock() {
	local tmux_lock_channel="$1"
	shift
	$@ && tmux wait-for -S "$tmux_lock_channel"
}

function get_running_tmux_session_with_regex() {
	local session_name_regex="$1"
	local tmux_sessions=( $(tmux list-sessions -F "#{session_name}") )
	local matched_session_running='false'
	local -i num_of_matched_sessions=0

	for sesh in "${tmux_sessions[@]}"; do
		if [[ "$sesh" =~ $session_name_regex ]]; then
			local matched_session_running='true'
			local num_of_matched_sessions=$((++num_of_matched_sessions))
			if [[ $num_of_matched_sessions -gt 1 ]]; then
				print_format "$style_error" "$message_multiple_running_tmux_sessions. Session #$num_of_matched_sessions: $sesh"
			fi
		fi
	done

	if [[ "$matched_session_running" = 'true' && $num_of_matched_sessions -eq 1 ]]; then
		for match in "${BASH_REMATCH[@]}"; do
			printf "%s\n" "$match"
		done
		return 0
	elif [[ "$matched_session_running" = 'true' ]]; then
		return 2
	else
		return 1
	fi
}

function create_tmux_windows_for_project() {
	local tmux_session_name="$1"
	local project="$2"
	local replace_first_window="$3"
	local project_type="$(get_project_type "$project")"
	local project_dir="$(get_project_dir "$project")"

	case "$project_type" in
		"$project_type_django")
			local win_name_django="${project}${tmux_win_name_django_suffix}"
			local win_name_celery="${project}${tmux_win_name_celery_suffix}"
			local project_celery_app_name="$(get_project_celery_app_name "$project")"

			if [[ "$replace_first_window" = 'true' ]]; then
				tmux new-window -dk -c "$project_dir"  -t "$tmux_session_name:$tmux_default_window_name" -n "$win_name_django" || return 1
			else
				tmux new-window -da -c "$project_dir" -t "$tmux_session_name:{end}" -n "$win_name_django" || return 1
			fi

			if [[ -n "$project_celery_app_name" ]]; then
				tmux new-window -da -c "$project_dir" -t "$tmux_session_name:{end}" -n "$win_name_celery" || return 1
				tmux split-window -c "$project_dir" -t "$tmux_session_name:$win_name_celery" || return 1
			fi
			;;
		"$project_type_node")
			local win_name_npm_watch="${project}${tmux_win_name_npm_watch_suffix}"

			if [[ "$replace_first_window" = 'true' ]]; then
				tmux new-window -dk -c "$project_dir" -t "$tmux_session_name:$tmux_default_window_name" -n "$win_name_npm_watch" || return 1
			else
				tmux new-window -da -c "$project_dir" -t "$tmux_session_name:{end}" -n "$win_name_npm_watch" || return 1
			fi
			;;
	esac

	return 0
}


######## COMMAND-SPECIFIC FUNCTIONS ########

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
		local project_db_name="$(get_project_db_name "$project")"
		setup_project_branch "$project" 'true' "$branch" 'true' 'true' || return 1
		create_clean_db "$project_db_name" || return 1

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
		restore_from_clean_db "$project_db_name" "$delete_db" || return 1

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
		goto_project "$project" 'false' "$branch" || return 1
		run_command "$@" || return 1
	else
		print_format "$style_error" "$message_unknown_project: '$project'"
		return 1
	fi

	return 0
}

function has_file_changes_between_branches_based_on_pattern() {
	local project="$1"
	local branch_from="$2"
	local branch_to="$3"
	local file_pattern_to_find="$4"
	local project_dir="$(get_project_dir "$project")"
	local git_output="$(git --no-pager -C "$project_dir" diff --name-only "${branch_from}...${branch_to}" "$file_pattern_to_find" )"

	if [[ -z "$git_output" ]]; then
		printf "false"
		return 1
	else
		printf "true"
		return 0
	fi
}

function update_tmux_windows_for_project() {
	local tmux_session_name="$1"
	local project="$2"
	local branch_from="$3"
	local branch_to="$4"
	local project_dir="$(get_project_dir "$project")"
	local project_type="$(get_project_type "$project")"

	tmux new-window -da -t "$tmux_session_name:{end}" -n "$project-$tmux_default_window_name" || return 1

	case "$project_type" in
		"$project_type_django")
			# If there is a currently running session, check what the most effecient way to update is.
			# Otherwise update everything
			if [[ -n "$branch_from" ]]; then
				local run_install="$(has_file_changes_between_branches_based_on_pattern "$project" "$branch_from" \
					"$branch_to" "$file_pattern_py_requirments" )"
				local run_migrations="$(has_file_changes_between_branches_based_on_pattern "$project" "$branch_from" \
					"$branch_to" "$file_pattern_django_migrations" )"
				local load_ts_templates="$(has_file_changes_between_branches_based_on_pattern "$project" "$branch_from" \
					"$branch_to" "$file_pattern_ts_templates" )"
			else
				local run_install='true'
				local run_migrations='true'
				local load_ts_templates='true'
			fi

			local win_name_django="${project}${tmux_win_name_django_suffix}"
			local win_name_celery="${project}${tmux_win_name_celery_suffix}"
			local project_celery_app_name="$(get_project_celery_app_name "$project")"
			local project_port="$(get_project_port "$project")"

			printf "run_install = $run_install\n"
			printf "run_migrations = $run_migrations\n"
			printf "load_ts_templates = $load_ts_templates\n"

			if [[ -n "$project_celery_app_name" && -n "$branch_from" ]]; then
				tmux send-keys -t "$tmux_session_name:$win_name_celery.0" "C-c" "C-l" || return 1
				tmux send-keys -t "$tmux_session_name:$win_name_celery.1" "C-c" "C-l" || return 1
			fi

			if [[ "$run_install" = 'true' && -n "$branch_from" ]]; then
				tmux send-keys -t "$tmux_session_name:$win_name_django" "C-c" "C-l" || return 1
			fi

			tmux send-keys -t "$tmux_session_name:$project-$tmux_default_window_name" \
				"om script-run run_command_with_tmux_unlock $tmux_default_lock_channel " \
				"setup_project_branch $project $run_install $branch_to $run_migrations $load_ts_templates" "C-m" || return 1
			tmux wait-for $tmux_default_lock_channel

			if [[ -n "$project_celery_app_name" ]]; then
				tmux send-keys -t "$tmux_session_name:$win_name_celery.0" \
					"om script-run run_django_start_celery $project $project_celery_app_name high_priority" "C-m" || return 1
				tmux send-keys -t "$tmux_session_name:$win_name_celery.1" \
					"om script-run run_django_start_celery $project $project_celery_app_name" "C-m" || return 1
			fi

			if [[ "$run_install" = 'true' ]]; then
				tmux send-keys -t "$tmux_session_name:$win_name_django" \
					"om script-run run_django_start_server $project $project_port" "C-m" || return 1
			fi
			;;

		"$project_type_node")
			if [[ -n "$branch_from" ]]; then
				local run_install="$(has_file_changes_between_branches_based_on_pattern "$project" "$branch_from" \
					"$branch_to" "$file_pattern_py_requirments" )"
			else
				local run_install='true'
			fi

			local win_name_npm_watch="${project}${tmux_win_name_npm_watch_suffix}"

			printf "run_install = $run_install\n"

			if [[ "$run_install" = 'true' ]]; then
				if [[ -n "$branch_from" ]]; then
					tmux send-keys -t "$tmux_session_name:$win_name_npm_watch" "C-c" "C-l" || return 1
				fi

				tmux send-keys -t "$tmux_session_name:$project-$tmux_default_window_name" \
					"om script-run run_command_with_tmux_unlock $tmux_default_lock_channel " \
					"setup_project_branch $project $run_install $branch_to" "C-m" || return 1
				tmux wait-for $tmux_default_lock_channel
				tmux send-keys -t "$tmux_session_name:$win_name_npm_watch" \
					"om script-run run_npm_run_watch $project" "C-m" || return 1
			else
				# No need to restart the npm watch if there are no changes in the node requirements
				tmux send-keys -t "$tmux_session_name:$project-$tmux_default_window_name" \
					"om script-run setup_project_branch $project $run_install $branch_to" "C-m" || return 1
			fi
			;;
	esac

	# tmux kill-window -t "$tmux_session_name:$tmux_default_window_name"

	return 0
}

function build() {
	local ba_branch_to="$1"
	local old_build_running='false'

	if [[ $# -eq 0 ]]; then
		print_format "$style_error" "$message_not_enough_args"
		return 1

	elif [[ $# -ge 2 ]]; then
		shift
		for (( i=1; i<=$#; i+=2 )); do
			local option="${!i}"
			local branch_index=$((i + 1))
			local branch="${!branch_index}"

			if is_valid_build_command_option "$option"; then
				case "$option" in
					"$option_om"|"$option_om_short")
						if [[ $# -lt $branch_index ]]; then
							print_format "$style_error" "$message_incorrect_num_of_args"
							return 1
						else
							local om_branch_to="$branch"
						fi
						;;
					"$option_kod"|"$option_kod_short")
						if [[ $# -lt $branch_index ]]; then
							print_format "$style_error" "$message_incorrect_num_of_args"
							return 1
						else
							local kod_branch_to="$branch"
						fi
						;;
				esac
			else
				print_format "$style_rror" "$message_unknown_arg: $option"
				printf "$message_usage\n"
				return 1
			fi

		done
	fi

	printf "%s\n" "ba_branch_to = $ba_branch_to"
	printf "%s\n" "om_branch_to = $om_branch_to"
	printf "%s\n" "kod_branch_to = $kod_branch_to"

	# Starts tmux server only if it is not already running
	tmux start-server

	# TODO: Figure out how to fix this hack - why is it not working in the script?
	local tmux_session_rematch=( $(get_running_tmux_session_with_regex "$sesh_name_regex") )
	get_running_tmux_session_with_regex "$sesh_name_regex" &> /dev/null

	local tmux_session_rematch_ret=$?
	local tmux_sesh_name_new="${script_name}${sesh_name_sep}${project_ba_short}=${ba_branch_to}"
	tmux_sesh_name_new+="$([[ -z "$om_branch_to" ]] || printf "${sesh_name_sep}${project_om_short}=${om_branch_to}")"
	tmux_sesh_name_new+="$([[ -z "$kod_branch_to" ]] || printf "${sesh_name_sep}${project_kod_short}=${kod_branch_to}")"

	printf "ret_value = $tmux_session_rematch_ret\n"

	if [[ $tmux_session_rematch_ret -ge 2 ]]; then
		return 1

	elif [[ $tmux_session_rematch_ret -eq 1 ]]; then
		tmux new-session -d -s "$tmux_sesh_name_new" -n "$tmux_default_window_name"
		create_tmux_windows_for_project "$tmux_sesh_name_new" "$project_ba_short" 'true'
		create_tmux_windows_for_project "$tmux_sesh_name_new" "$project_ba_node_short" 'false'

		if [[ -n "$om_branch_to" ]]; then
			create_tmux_windows_for_project "$tmux_sesh_name_new" "$project_om_short" 'false'
		fi

		if [[ -n "$kod_branch_to" ]]; then
			create_tmux_windows_for_project "$tmux_sesh_name_new" "$project_kod_short" 'false'
		fi

	else
		local tmux_sesh_name_old="${tmux_session_rematch[0]}"

		for (( i=0; i<${#tmux_session_rematch[@]}; i++ )); do
			local match="${tmux_session_rematch[$i]}"
			local -i after_match_index=$((i + 1))

			if is_valid_project_tag_for_build_command "$match"; then
				case "$match" in
					"$project_ba_short")
						local ba_branch_from="${tmux_session_rematch[$after_match_index]}"
						;;
					"$project_om_short")
						local om_branch_from="${tmux_session_rematch[$after_match_index]}"
						;;
					"$project_kod_short")
						local kod_branch_from="${tmux_session_rematch[$after_match_index]}"
						;;
				esac
			fi
		done

		tmux rename-session -t "$tmux_sesh_name_old" "$tmux_sesh_name_new"
	fi

	printf "%s\n" "ba_branch_from = $ba_branch_from"
	printf "%s\n" "om_branch_from = $om_branch_from"
	printf "%s\n" "kod_branch_from = $kod_branch_from"

	# Update the tmux session with new code in the most effecient way possible - services are only restarted if required
	update_tmux_windows_for_project "$tmux_sesh_name_new" "$project_ba_short" "$ba_branch_from" "$ba_branch_to" || return 1
	update_tmux_windows_for_project "$tmux_sesh_name_new" "$project_ba_node_short" "$ba_branch_from" "$ba_branch_to" || return 1
	update_tmux_windows_for_project "$tmux_sesh_name_new" "$project_om_short" "$om_branch_from" "$om_branch_to" || return 1
	update_tmux_windows_for_project "$tmux_sesh_name_new" "$project_kod_short" "$kod_branch_from" "$kod_branch_to" || return 1

	return 0
}

function script_run() {
	$@ || print_format "$style_error" "$message_function_returned_error"
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
		"$command_scipt_run")
			script_run "$@" || return 1
			;;
	esac

	return 0
}


######## MAIN SCRIPT ########

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

