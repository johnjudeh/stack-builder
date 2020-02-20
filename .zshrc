# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/john/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
#plugins=(
#  git
#)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias ohmyzsh="mate ~/.oh-my-zsh"

export LC_ALL=en_GB.UTF-8
export VENV_ROOT=/Users/john/virtualenvs
export BA_ROOT=/Users/john/projects/bankangle
export BA_NODE_ROOT=$BA_ROOT/assets/
export KODIAK_ROOT=/Users/john/projects/kodiak
export OM_ROOT=/Users/john/projects/om-elements
export BA_VENV=ba-py
export KODIAK_VENV=kodiak-py
export BA_NENV=ba-node
export OM_NENV=om-node
export BA_DB=ba
export BA_CELERY_APP=bankangle
export TMUX_LOCK_CHANNEL=lock

alias sm="./manage.py showmigrations | grep '\[ \]'"
alias ipy="ipython"
alias cpwd="pwd | pbcopy"
alias zshconfig="mate ~/.zshrc"
alias tks="tmux kill-session -t"
alias ta="tmux attach" 
alias tat="tmux attach -t" 
alias tls="tmux ls"

function pyactivate() {
	source $VENV_ROOT/py/$1/bin/activate
}

function nodeactivate() {
	source $VENV_ROOT/node/$1/bin/activate
}

function print_title() {
	echo ""
	echo ""
	echo $1
	echo "====================================================="
}

function change_directory() {
	print_title "Changing directory to '$1'"
	cd $1
}

function checkout_branch() {
	print_title "Checking out branch '$1'"
	git fetch --all
	git checkout $1
	git pull
}

function load_env() {
	print_title "Loading '$1' environment"
	if [ $1 = python ]; then
		pyactivate $2
		if [ $3 = "1" ]; then
			pip install -r requirements.txt
		fi
	
	elif [ $1 = node ]; then
		nodeactivate $2
		if [ $3 = "1" ]; then
			npm install
			git checkout -- package-lock.json
		fi

	fi
}

# TODO: A way to easily create a new database and migrate / load_dummy_data on it
function create_db() {
	# Args:
	# - $1 - new db name
	# - $2 - create from template?
	# - $3 - template name
	print_title "Creating database $1"
	# if [ ]; then 	
}

function create_clean_db() {
	print_title "Creating clean copy of database '$1'"
	# Create clean copy of database, overwriting it if it already exists
	if [ "$(psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$1_clean' ")" = "1" ]; then
		psql -c "
			DROP DATABASE \"$1_clean\";
		"
	fi
	psql -c "
		CREATE DATABASE \"$1_clean\" WITH TEMPLATE \"$1\";
	"
}

function restore_clean_db() {
	# $1 - db to restore
	# $2 - flag for deleting clean db
	
	print_title "Restoring database '$1'"

	# Stop processes connected to db quickly
	psql -c "
		SELECT pg_terminate_backend(pg_stat_activity.pid)
		FROM pg_stat_activity
		WHERE pg_stat_activity.datname = '$1'
		AND pid <> pg_backend_pid();
	"

	# Drop altered db
	psql -c "
		DROP DATABASE \"$1\";
	"

	# Restore clean database to old name
	psql -c "
		CREATE DATABASE \"$1\" WITH TEMPLATE \"$1_clean\";
	"
	
	# Drop clean db if flag is set
	if [ $2 = "1" ]; then
		psql -c "
			DROP DATABASE \"$1_clean\";
		"
	fi
} 

function django_migrate_db() {
	print_title "Migrating database"
	python manage.py migrate
}

function load_termsheet_templates() {
	print_title "Loading termsheet templates"
	python manage.py load_termsheet_templates --noinput
}

function django_start_server() {
	print_title "Starting django server on port '$1'"
	python manage.py runserver $1
}

function npm_run_watch() {
	print_title "Running npm watch"
	npm run watch
}

function init_django_project() {
	# $1 - project root
	# $2 - branch to use for initialisation
	# $3 - pyenv name
	# $4 - clean db to store
	change_directory $1
	checkout_branch $2
	load_env python $3 1
	django_migrate_db
	load_termsheet_templates
	create_clean_db $4
}

function cleanup_django_project() {
	# $1 - db to restore
	# $2 - destroy clean db?
	restore_clean_db $1 $2
	deactivate
}

function goto_project() {
	# $1 - project root
	# $2 - env type (python or node)
	# $3 - virtual env name
	# $4 - install packages?
	change_directory $1
	load_env $2 $3 $4
}

function setup_django_branch() {
	# $1 - project root
	# $2 - pyenv name
	# $3 - flag for installing env requirements
	# $4 - checkout branch?
	# $5 - git branch name
	# $6 - flag to run migrations
	goto_project $1 python $2 $3
	if [ $4 = "1" ]; then
		checkout_branch $5
	fi
	if [ $6 = "1" ]; then
		django_migrate_db
		load_termsheet_templates
	fi
}

function start_django_server() {
	# $1 - project root
	# $2 - pyenv name
	# $3 - flag for installing env requirements
	# $4 - checkout branch?
	# $5 - git branch name
	# $6 - flag to run migrations
 	# $7 - port for server
	setup_django_branch $1 $2 $3 $4 $5 $6	
	django_start_server $7
}

function start_django_celery_worker() {
	# $1 - project root
	# $2 - pyenv name
	# $3 - flag for installing env requirements
	# $4 - checkout branch?
	# $5 - git branch name
	# $6 - flag to run migrations
	# $7 - celery app
 	# $8 - is high priority worker?
	setup_django_branch $1 $2 $3 $4 $5 $6
	if [ $8 = "1" ]; then
		celery -A $7 worker -Q high_priority
	else
		celery -A $7 worker
	fi
}

function start_node_server() {
	# $1 - project root
	# $2 - checkout branch?
	# $3 - git branch name
	# $4 - nodeenv name
	# $5 - flag for installing env requirements
	change_directory $1
	if [ $2 = "1" ]; then
		checkout_branch $3
	fi
	load_env node $4 $5
	npm_run_watch
}

function run_command_with_tmux_unlock() {
	# $@ - command and its arguments
	$@ && tmux wait-for -S $TMUX_LOCK_CHANNEL
}

function init_ba() {
	init_django_project $BA_ROOT master $BA_VENV $BA_DB
}

function cleanup_ba() {
	# $1 - destroy clean db?
	cleanup_django_project $BA_DB $1
}

function goto_ba() {
	goto_project $BA_ROOT python $BA_VENV 0
}

function goto_ba_node() {
	goto_project $BA_NODE_ROOT node $BA_NENV 0
}

function goto_om() {
	goto_project $OM_ROOT node $OM_NENV 0
}

function setup_ba_django_branch_with_tmux_unlock() {

	# $1 - branch to checkout
	if [ $# -ne 1 ]; then
		echo "Incorrect number of arguments"
		return 1
	else
		run_command_with_tmux_unlock setup_django_branch $BA_ROOT $BA_VENV 1 1 $1 1  
	fi 
}

function start_ba_django_server() {
	# $1 - branch to checkout (optional)
	if [ $# -ne 1 ]; then
		start_django_server $BA_ROOT $BA_VENV 1 1 develop 1 8000
	else
		start_django_server $BA_ROOT $BA_VENV 1 1 $1 1 8000
	fi 
}

function start_ba_celery() {
	# $1 - is high priority worker? 
	if [ $# -ne 1 ]; then
		start_django_celery_worker $BA_ROOT $BA_VENV 0 0 na 0 $BA_CELERY_APP 0
	else
		start_django_celery_worker $BA_ROOT $BA_VENV 0 0 na 0 $BA_CELERY_APP $1
	fi
}

function start_bankangle_node_server() {
	start_node_server $BA_NODE_ROOT 0 develop $BA_NENV 1
}

function start_om_node_server() {
	# $1 - branch to checkout (optional)
	if [ $# -ne 1 ]; then
		start_node_server $OM_ROOT 1 develop $OM_NENV 1
	else
		start_node_server $OM_ROOT 1 $1 $OM_NENV 1
	fi
}

function og_build() {
	# Args:
	# - $1 - bankangle branch
	# - $2 - om-elements branch
	
	# Validate number of arguments passed
	if [ $# -ne 2 ]; then
		echo "Incorrect number of arguments. 2 required"
		return 1
	fi

	# Setup session and window names 
	local sesh="br=$1<>$2"
	local win_ba_dj="ba_django"
	local win_ba_cel="ba_cel"
	local win_ba_node="ba_node"
	local win_om_node="om_node"
	
	# Setup the tmux view for the different services
	tmux new-session -d -s $sesh -n $win_ba_dj
	tmux new-window -da -t $sesh:$ -n $win_ba_cel
	tmux split-window -t $sesh:$win_ba_cel
	tmux new-window -da -t $sesh:$ -n $win_ba_node
	tmux new-window -da -t $sesh:$ -n $win_om_node
	
	# Start with om-elements build as it's independent of anything else	
	tmux send-keys -t $sesh:$win_om_node "start_om_node_server $2" C-m 

	# Setup the bankangle git branch we want to see before starting any services	
	tmux send-keys -t $sesh:$win_ba_dj "setup_ba_django_branch_with_tmux_unlock $1" C-m
	tmux wait-for $TMUX_LOCK_CHANNEL
	
	# Once branch is setup, start the django server
	tmux send-keys -t $sesh:$win_ba_dj "django_start_server 8000" C-m
	tmux send-keys -t $sesh:$win_ba_node "start_bankangle_node_server" C-m 

	# Finally, start the two celery workers
	tmux send-keys -t $sesh:$win_ba_cel.0 "start_ba_celery 1" C-m
	tmux send-keys -t $sesh:$win_ba_cel.1 "start_ba_celery 0" C-m
}

function og_checkout() {
	# Args:
	# - $1 - bankangle branch	
	# - $2 - om-elements branch
	# - $3 - run migrations?
	
	# Setup session and window names 
	local sesh="br=$1<>$2" # TODO: need the name of the old session...
	local win_ba_dj="ba_django"
	local win_ba_cel="ba_cel"
	local win_ba_node="ba_node"
	local win_om_node="om_node"
	local win_ba_updater="ba_updater"
	local win_om_updater="om_updater"

	# Validate number of arguments passed
	if [ $# -lt 2 ] && [ $# -gt 3 ]; then
		echo "Incorrect number of arguments. 2-3 required"
		return 1
	fi
	
	# Create windows for updating branches
	tmux new-window -da -t $sesh:$ -n $win_ba_updater
	tmux new-window -da -t $sesh:$ -n $win_om_updater

	# Update om-elements branch
	tmux send-keys -t $sesh:$win_om_updater "goto_om && checkout_branch $2" C-m
		
	# Update bankangle branch and stop celery
	tmux send-keys -t $sesh:$win_ba_cel.0 C-c
	tmux send-keys -t $sesh:$win_ba_cel.1 C-c
	tmux send-keys -t $sesh:$win_ba_updater \
		"goto_ba && run_command_with_tmux_unlock checkout_branch $1" C-m
	tmux wait-for $TMUX_LOCK_CHANNEL
	
	# Run django migrations if needed
	if [ $# -eq 3 ] && [ $3 = "1" ]; then
		tmux send-keys -t $sesh:$win_ba_updater \ 
			"goto_ba && run_command_with_tmux_unlock django_migrate_db" C-m
		tmux wait-for $TMUX_LOCK_CHANNEL
	fi
	
	# Restart celery services once all changes have been made
	tmux send-keys -t $sesh:$win_ba_cel.0 'start_ba_celery 1' C-m
	tmux send-keys -t $sesh:$win_ba_cel.1 'start_ba_celery 0' C-m
}

