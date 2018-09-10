#!/bin/bash

# ============
# SCRIPT SETUP
# ============

set -o errexit
set -o nounset

# =========
# CONSTANTS
# =========

readonly USERNAME=$(whoami)
readonly XAUTH=/tmp/.docker.xauth

# ===============================
# UTILITY FUNCTIONS AND VARIABLES
# ===============================

Color_Off='\e[0m'
BRed='\e[1;31m'
BBlue='\e[1;34m'
BGreen='\e[1;32m'

function msg()
{
	echo -e "$BGreen==>$Color_Off $1"
}

function msg2()
{
	echo -e "  $BBlue->$Color_Off $1"
}

function msg3()
{
	echo -e "  $1"
}

function err()
{
	echo -e "$BRed==>$Color_Off $1"
}

function err2()
{
	echo -e "  $BRed==>$Color_Off $1"
}

function print_help()
{
	echo "Usage: $0 [OPTIONS] ... [COMMAND]"
	echo
	echo "Helper script for spawning containers used as development setup"
	echo
	echo "Commands:"
	echo
	echo "  start|up    Start the composed setup"
	echo "  stop|down   Stop the composed setup"
	# echo "  status      Prints the status of the setup"
	echo
	echo "Optional arguments:"
	echo "  -p    Project directory mounted in the HOME (default: /tmp/docker-tmpfolder)"
	echo
	echo "Examples:"
	echo "$0 -p /home/user/git/myproject start"
	echo
	echo "Diego Ferigo: <diego.ferigo@iit.it>"
	echo "iCub Facility - Italian Institute of Technology"
}

# ================
# SCRIPT FUNCTIONS
# ================

function find_docker()
{
    DOCKER=$(which docker)
    
    if [ ! -x "$DOCKER" ] ; then
        err "Command docker not found in PATH."
        exit 1
    fi
}

function create_xauth()
{
    if [ -e $XAUTH ] ; then
        msg2 "Removing old authentication file"
        rm -rf $XAUTH
    fi
    
    msg2 "Creating authentication file"
    touch $XAUTH
    
    msg2 "Granting X11 permissions"
    if [ $(xauth nlist $DISPLAY | grep -v ffff | wc -l) -gt 1 ] ; then
        err "Your system has more than one authentication entry. Exiting" && exit 1
    fi
    xauth nlist $DISPLAY | grep -v ffff | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
    chmod 664 $XAUTH
}

function remove_xauth()
{
    if [ -e $XAUTH ] ; then
        msg2 "Deleting the X11 authentication file"
        rm -rf $XAUTH
    fi
}

# ====================
# DOCKER OPTIONS UTILS
# ====================

function initialize_options()
{
    DOCKER_OPTION_IMAGE=
    DOCKER_OPTION_COMMAND=
    DOCKER_OPTION_EXTRA=
    DOCKER_OPTION_LABEL=
    DOCKER_OPTION_MAC=
    DOCKER_OPTION_NETWORK=
    DOCKER_OPTION_STOP_SIGNAL=
    DOCKER_OPTION_EXPOSED_PORTS=
    DOCKER_OPTION_PUBLISHED_PORTS=
    DOCKER_OPTION_ENVVARS=
    DOCKER_OPTION_VOLUMES=
    DOCKER_OPTION_DEVICES=
    DOCKER_OPTION_SECURITY=
    DOCKER_OPTION_TMPFS=
    DOCKER_OPTION_CAP=
}

function set_image()
{
    DOCKER_OPTION_IMAGE="$1"
}

function set_command()
{
    DOCKER_OPTION_COMMAND="$1"
}

function set_runtime()
{
    DOCKER_OPTION_RUNTIME="--runtime $1"
}

function set_name()
{
    DOCKER_OPTION_LABEL="--name $1"
}

function set_macaddr()
{
    DOCKER_OPTION_MAC="--mac-address=$1"
}

function set_stopsignal()
{
    DOCKER_OPTION_STOP_SIGNAL="--stop-signal $1"
}

function set_network()
{
    DOCKER_OPTION_NETWORK="--network $1"
}

function add_extra_option()
{
    DOCKER_OPTION_EXTRA+="$1 "
}

function publish_port()
{
    DOCKER_OPTION_PUBLISHED_PORTS+="--publish $1 "
}

function expose_port()
{
    DOCKER_OPTION_EXPOSED_PORTS+="--expose $1 "
}

function add_envvar()
{
    DOCKER_OPTION_ENVVARS+='-e ' # TODO
    DOCKER_OPTION_ENVVARS+="$1 "
}

function add_volume()
{
    DOCKER_OPTION_VOLUMES+="--volume $1 "
}

function add_device()
{
    DOCKER_OPTION_DEVICES+="--device $1 "
}

function add_tmpfs()
{
    DOCKER_OPTION_TMPFS+="--tmpfs $1 "
}

function add_cap()
{
    DOCKER_OPTION_CAP+="--cap-add $1 "
}

function add_security()
{
    DOCKER_OPTION_SECURITY+="--security-opt $1"
}

function add_persistent_folder()
{
    # TODO: spaces in path?

    if [ ! -d $1 ] ; then
        mkdir -p $1 || (err2 "Unable to create $1" && exit 1)
    fi
    
    mount_point="$1"
    if (( $# > 1 )) ; then
        mount_point="$2"
    fi
    
    add_volume "$1:$mount_point:rw"
}

function add_persistent_file()
{
    if [ ! -f $1 ] ; then
        mkdir $(dirname $1) || (err2 "Unable to create $(dirname $1)" && exit 1)
        touch $1 || (err2 "Unable to create $1" && exit 1)
    fi
    
    mount_point="$1"
    if (( $# > 1 )) ; then
        mount_point="$2"
    fi
    
    add_volume "$1:$mount_point:rw"
}

# ========================
# HIGH LEVEL CONFIGURATION
# ========================

function configure_base()
{
    CONTAINER_NAME="development"

    # Image
    set_image "diegoferigo/development:nvidia-devel"
    set_name "$CONTAINER_NAME"
    
    add_extra_option "-it"
    add_extra_option "-d"
    add_extra_option "--rm"
    
    # Runtime
    set_runtime "runc"
    
    # Default command
    set_command "su $USERNAME"
    
    # Runtime user
    add_envvar "USERNAME=$USERNAME"
    add_envvar "USER_UID=$(id -u)"
    add_envvar "USER_GID=$(id -g)"
    #add_envvar "COLUMNS=$COLUMNS"
    #add_envvar "LINES=$LINES"
    
    add_tmpfs /tmp
    
    add_device /dev/dri
    add_volume /dev/shm
}

function configure_X11_xauth
{
    add_envvar "DISPLAY"
    add_envvar "XAUTHORITY=$XAUTH"
    
    add_volume "/tmp/.X11-unix:/tmp/.X11-unix:rw"
    add_volume "$XAUTH:$XAUTH:rw"
    
    CREATE_XAUTH=1
}

function configure_X11_xhost
{
    add_envvar "DISPLAY"    
    add_volume "/tmp/.X11-unix:/tmp/.X11-unix:rw"
    
    XHOST_GRANT_USER=1

    # trap ctrl_c EXIT
    trap ctrl_c INT
}

function ctrl_c()
{
    xhost -si:localuser:$(whoami)
}

function configure_development()
{
    add_persistent_file $HOME/.dockerdot/bash_history $HOME/.bash_history

    add_persistent_folder $HOME/.dockerdot/ccache  $HOME/.ccache
    add_persistent_folder $HOME/.dockerdot/atom $HOME/.atom
    add_persistent_folder $HOME/.dockerdot/config/atom $HOME/.config/Atom
    add_persistent_folder $HOME/.dockerdot/gitkraken $HOME/.gitkraken
    add_persistent_folder $HOME/.dockerdot/config/qtcreator $HOME/.config/QtProject
    
    # TODO: allows using external yarp server but has issues with dbus, preventing the usage of GUIs
    # set_network "host"
        
    expose_port "10000/tcp"
    expose_port "10000/udp"
    
    add_envvar "YARP_NAMESPACE=/$USERNAME"
    add_envvar "COPY_ATOM_PACKAGES=1"
    add_envvar "CHOWN_SOURCES=1"

    # Git
    add_envvar "GIT_USER_NAME=Diego\ Ferigo"
    add_envvar "GIT_USER_EMAIL=diego.ferigo@iit.it"
}

function configure_matlab()
{
    HOST_MATLAB_DIR=/usr/local/MATLAB/R2018a
    HOST_MATLAB_DOT_DIR=/home/dferigo/.dockerdot/matlab
    
    add_volume "$HOST_MATLAB_DIR:/usr/local/MATLAB:rw"
    add_persistent_folder "$HOST_MATLAB_DOT_DIR" $HOME/.matlab
    
    set_macaddr "$(cat /sys/class/net/wlp2s0/address)"
}

function configure_systemd()
{
    # https://developers.redhat.com/blog/2016/09/13/running-systemd-in-a-non-privileged-container/
    # https://github.com/solita/docker-systemd
    # https://github.com/docker/for-linux/issues/106#issuecomment-330518243
    
    add_extra_option "--detach"
    
    # add_envvar "container=docker" # TODO
    
    add_cap SYS_ADMIN
    
    add_tmpfs /run
    add_tmpfs /run/lock
    
    set_stopsignal "SIGRTMIN+3"
    
    add_volume "/sys/fs/cgroup:/sys/fs/cgroup:ro"
    set_command "/sbin/init"
}

function configure_gdb()
{
    add_cap SYS_PTRACE
    add_security "seccomp:unconfined"
}

function handle_project_dir()
{
    readonly PROJECT_DIR_DEFAULT="/tmp/docker-tmpfolder"

    if [[ -z ${1:+x} || ! -d $1 ]] ; then
        msg2 "The project folder does not exist. Using \"$PROJECT_DIR_DEFAULT\""
        PROJECT_DIR=$PROJECT_DIR_DEFAULT
    else
        msg2 "Project folder: $1"
        PROJECT_DIR=$1
    fi

    PROJECT_BASENAME=$(basename $PROJECT_DIR)
    
    add_persistent_folder $PROJECT_DIR $HOME/$PROJECT_BASENAME
}

# ===================
# DOCKER COMMAND LINE
# ===================

function configure()
{
    configure_base
    configure_development
    configure_gdb
    configure_matlab
    #set_runtime "nvidia"
    
    configure_X11_xauth
    #configure_X11_xhost
    
    #configure_systemd
    add_extra_option "--init"
}

function configure_tools()
{
    configure_base
    set_image "diegoferigo/tools:nvidia"
    
   set_network "host"
    configure_X11_xauth
    add_extra_option "--init"
}

function docker_run_cmdline()
{
    command="docker run "
    command+="$DOCKER_OPTION_EXTRA"
    command+="$DOCKER_OPTION_NETWORK"
    command+="$DOCKER_OPTION_LABEL "
    command+="$DOCKER_OPTION_RUNTIME "
    command+="$DOCKER_OPTION_MAC "
    command+="$DOCKER_OPTION_STOP_SIGNAL"
    command+="$DOCKER_OPTION_EXPOSED_PORTS"
    command+="$DOCKER_OPTION_PUBLISHED_PORTS"
    command+="$DOCKER_OPTION_ENVVARS"
    command+="$DOCKER_OPTION_SECURITY "
    command+="$DOCKER_OPTION_CAP"
    command+="$DOCKER_OPTION_DEVICES"
    command+="$DOCKER_OPTION_VOLUMES"
    command+="$DOCKER_OPTION_TMPFS"
    command+="$DOCKER_OPTION_IMAGE "
    command+="$DOCKER_OPTION_COMMAND"
    echo $command
    eval $command
}

function control()
{
    echo $2
    
	case $1 in
		start|up)
			msg "Starting up..."
			
			# Initialize the docker options
			initialize_options
			
			# Handle main project directory
			handle_project_dir $2
			
			msg "Parsing options"
            configure
            #configure_tools
			
			CREATE_XAUTH=${CREATE_XAUTH:-0}
			if [ $CREATE_XAUTH -eq 1 ] ; then
                msg "Setting up X11 resources"
                create_xauth
            fi
            
            XHOST_GRANT_USER=${XHOST_GRANT_USER:-0}
            if [ $XHOST_GRANT_USER -eq 1 ] ; then
                msg "Allowing $(whoami) to access X11 resources"
                xhost +si:localuser:$(whoami)
            fi

			msg "Starting the container"
			docker_run_cmdline
			;;
		stop|down)
			msg "Stopping..."
			
			initialize_options
			configure
			
			CREATE_XAUTH=${CREATE_XAUTH:-0}
			if [ $CREATE_XAUTH -eq 1 ] ; then
                remove_xauth
            fi
			
			XHOST_GRANT_USER=${XHOST_GRANT_USER:-0}
			if [ $XHOST_GRANT_USER -eq 1 ] ; then
                xhost -si:localuser:$(whoami)
            fi
			
			msg2 "Removing the containers"
			$DOCKER stop $CONTAINER_NAME || exit 1
			;;
        rm)
        ;;
		status)
			# TODO: show the status of the composed system
			exit $EC_NOOP
			;;
		*)
			err "$1: command not found"
			echo
			print_help
			exit $EC_NOOP
			;;
	 esac
}

# ====
# MAIN
# ====

# Parse cmdline
while getopts :p: OPT ; do
	case $OPT in
	p)
		IN_OPT_WDIR=$OPTARG
		;;
	\?)
		print_help
		exit $EC_NOOP
		;;
	esac
done

# Default arguments
IN_OPT_WDIR=${IN_OPT_WDIR:-" "}

# Get the last parameter(s), i.e. the command to execute
shift $((OPTIND - 1))
COMMAND="$@"

find_docker
control $COMMAND "$IN_OPT_WDIR"
