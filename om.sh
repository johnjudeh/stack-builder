#!/usr/bin/env bash

# Constants - Declare these as constants

version='1.0.0'

command_init='init'
command_build='build'
command_cleanup='cleanup'
commands=( "$command_init" "$command_build" "$command_cleanup" )

option_help='--help'
option_help_short='-h'
option_version='--version'
option_version_short='-v'
base_options=( "$option_help" "$option_help_short" "$option_version" "$option_version_short" )

usage="usage: om [$option_help|$option_help_short] [$option_version|$option_version_short] <command> [<args>]"
usage_help="$usage

There are a number of possible commands:

	$command_init		Updates project for specified branches and saves a version of the database

			om $command_init <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]


	$command_build		Builds the origin markets stack with the specified branches

			om $command_build <ba-branch> [--om=<om-branch>] [--kod=<kodiaik-branch>]


	$command_cleanup		Cleans up project to last time init was run

			om $command_cleanup [--last-snapshot|-ls]
"

# Command Functions

function is_in_array() {
	local search="$1"
	local arr=("${@:2}")

	for val in "${arr[@]}"; do
		if [[ $search = $val ]]; then
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

	case $option in
		$option_version | $option_version_short)
			printf "$version\n"
			;;
		$option_help | $option_help_short)
			printf "$usage_help\n"
			;;
	esac

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

	case $command in
		$command_init)
			init "$@" || return 1
			;;
		$command_build)
			build "$@" || return 1
			;;
		$command_cleanup)
			cleanup "$@" || return 1
			;;
	esac

	return 0
}


# Main script

if [[ $# -eq 0 ]]; then
	# Not enough arguments passed
	printf "$usage_help\n"
	exit 1

elif is_valid_base_option "$1" "${base_options[@]}"; then
	# Command line option passed. Ignores all arguments after
	handle_base_options "$1" || exit 1
	exit 0

elif is_valid_command "$1" "${commands[@]}"; then
	handle_command "$@" || exit 1
	exit 1

else
	printf "Unknown argument: $1\n"
	printf "$usage\n"
	exit 1

fi

