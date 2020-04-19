# Stack Builder


## Description

A command line tool to manage a stack of projects in a web application.

The tool can be used for the following tasks:
 * Build a stack of projects for specific git branches
 * Create a local copy of a database before going into a dirty branch
 * Restore a database to a local clean copy after leaving a dirty branch
 * Run a command in a specific project from anywhere


## Installation

Start by cloning the project locally by typing the following into your terminal.

```bash
cd <chosen folder>
git clone git@git.originmarkets.com:johnjudeh/stack-builder.git
cd stack-builder
```

The project needs a few dependencies to run. [tmux](https://github.com/tmux/tmux/wiki), or Terminal
Multiplexer, emulates multiple windows in the same terminal window. It is used to manage the stack
of projects in your webapp. [jq](https://stedolan.github.io/jq/) is a JSON parser used to parse the
config file that describes your project stack.

Make sure you have [Homebrew](https://brew.sh/) installed and run the following commands.

```bash
brew install tmux
brew install jq
```

Once you have all the requirements installed, you need to put `sb`, the Stack Builder executable,
onto your `PATH`. You can do this by creating a symbolic link to the `sb` script into a folder
that your `PATH` is pointing to. A recommended directory for keeping user-specific scripts is
`~/bin`. If this directory is not on your `PATH`, make sure to add it in your `~/.zshrc` or
`~/.bash_prohile` depending on the kind of shell you are using. You can create the symbolic link as
follows.

```bash
ln -s /absolute/path/to/stack-builder/sb ~/bin/sb
```

Check this was successful by running the following in your terminal.

```bash
sb --version
```

Next, you need to setup your configuration file. The easiest way to do this is by using the
example file in this repo. However to learn more about how to set this up for a new project, look
at the [Config](#configuration) section below.

```bash
cp .sbconfig.json.example ~/.sbconfig.json
```

For the script to work, you need to set some environment variables that are defined in your config
file. Go to the [Config](#configuration) section to read about these in detail or run the following
command for a quick check.

```bash
sb check
```

Finally, you need to set up your projects to use the environment variables defined in your config
file. The idea here is that `sb`, your projects and any other utility can all access and amend the
characteristics of a project. For example, if you have a django project with a `dbName` environment
variable of `BA_DB`, then you need to set this up in your django settings file.

```python
DATABASES = {
   'default': {
       ...
       'NAME': os.getenv('BA_DB'),
       ...
   }
}
```

You also need to make sure that your dependent projects use the independent project urls if they
need them. An example of how this might be used is (bankangle):

```python
KODIAK_URL = os.getenv('KOD_URL')

ANGULAR_CONFIG_BASE_URL=os.getenv('OM_URL')

if ANGULAR_CONFIG_BASE_URL.startswith('file://'):
    js_files=[
        'main.js',
        'polyfills.js',
        'runtime.js',
        'scripts.js',
        'styles.js',
        'vendor.js',
    ]
    css_files = []
else:
    js_files = ['om-app.js']
    css_files = ['styles.css']

ANGULAR_CONFIG = AngularConf(
    base_url=ANGULAR_CONFIG_BASE_URL,
    js_files=js_files,
    css_files=css_files,
)
```

Once that's all set up, you can find out how to use it in the [Usage](#usage) section below or
type the following into your terminal.

```bash
sb --help
```


## Configuration

The configuration file is used to tell `sb` what your project stack looks like. It describes the
projects in your stack and any important details about them. The format is as follows:

```JSON
{
	"projects": [
		{...},
		{...}
	]
}
```

### Projects

Each project is a JSON object with a set of required keys:
 1. `name`: a unique sequence of alphanumeric characters and underscores
 2. `shortName`: a unique sequence of alphanumeric characters and underscores
 3. `char`: a unique single character
 4. `type`: either `django` or `node`
 5. `dependant`: either `true` or `false` based on whether the project requires other
projects to work properly. In the case of Origin, only bankangle is dependant
 6. `port`: the port number to run on. Only required for `django` projects
 7. `celeryAppName`: the celery app name used to run celery. Optional for projects that need
to run celery
 8. `environmentVariables`: a JSON object of environment variables names rather than values

Each project also has a set of required environment variables. These variable names need to
accessible and set in your own environment for the script to work.
 1. `rootDir`: the environment variable name that points to the project directory
 2. `virtualenvPath`: the environment variable that points to the path of your virtualenv. Required for
all project types
 3. `dbName`: the environment variable name that points to the database name. Only required for
`django` projects
 4. `url`: the environment variable name that points to the url the service is running at. This
is only required for projects that have the `urls` object detailed below

Finally, each project can have an optional set of urls. This is required for any project that
needs to be accessed by a dependant project. For example, if there is a service running at a
specific url, these variables specify how to access it. If any urls are defined, the two below are
required:
 1. `local`: The url of the service when it's being run locally
 2. `default`: The url of the project when it's not being run locally. Normally a live
environment


## Usage

The command line tool's usage is all detailed under the help command. This can be found by typing
the following into your terminal.

```bash
sb --help
sb -h
```

For commands that take projects as option flags, like the `build` command, the option flags allowed
depend on the config file. For example, a project with the following config:

```JSON
{
	"projects": [
		{
			"name": "bankangle",
			"shortName": "ba",
			"char": "b",
			...
		},
		...
	]
}
```

Can be targetted using either of these three ways:
 1. `sb build --bankangle <target-branch>`
 2. `sb build --ba <target-branch>`
 3. `sb build -b <target-branch>`


## Tests

Not yet written.


## Author

John Judeh

