# Colors, colors, colors
if [ $UID -ne 0 ]; then
	PS1='${debian_chroot:+($debian_chroot)}\[\e[36;1m\]\u\[\e[0m\]@\H:\[\e[30;1m\]\w\[\e[0m\]\[\e[00;36m\]$(__git_ps1 " (%s)")\[\e[36;1m\]>\[\e[0m\]\[\e[1m\] '
else
	PS1='${debian_chroot:+($debian_chroot)}\[\e[31;1m\]\u\[\e[0m\]@\H:\[\e[30;1m\]\w\[\e[31;1m\]#\[\e[0m\]\[\e[1m\] '
fi

# After changing user, cd inside $HOME. Use $(cd -) to get back to the previous folder
cd $HOME || return 1

# Configuration of the bash environment
# =====================================

# Reset PS1 color before command's output
trap 'echo -ne "\e[0m"' DEBUG

# Disable echo ^C when Ctrl+C is pressed
stty -echoctl

# Avoid using cd to change directory. Simply: ~# /etc
shopt -s autocd

# Case insensitive filename completion
shopt -s nocaseglob

# Autocorrect simple typos
shopt -s cdspell
shopt -s dirspell direxpand

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

# Disable completion when the input buffer is empty.  i.e. Hitting tab
# and waiting a long time for bash to expand all of $PATH.
shopt -s no_empty_cmd_completion

# History handling
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
shopt -s histappend
PROMPT_COMMAND='history -a'

# Mappings for Ctrl-left-arrow and Ctrl-right-arrow for words navigation
bind '"\e[1;5C": forward-word'
bind '"\e[1;5D": backward-word'
bind '"\e[5C": forward-word'
bind '"\e[5D": backward-word'
bind '"\e\e[C": forward-word'
bind '"\e\e[D": backward-word'

# Configuration of frameworks and tools
# =====================================

# Load utility functions
if [ -x /home/${USERNAME}/.bashrc-functions.sh ] ; then
	source /home/${USERNAME}/.bashrc-functions.sh
fi

# Explicitly enable gcc colored output
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Set the default editor
if [ -e $(which nano) ] ; then
	export EDITOR="nano"
	echo "include /usr/share/nano/*" > ~/.nanorc
fi

# Load the robotogy-superbuild environment
if [[ -e ${IIT_SOURCES}/robotology-superbuild/build/install/share/robotology-superbuild/setup.sh && -z $SUPERBUILD_SOURCED ]] ; then
    source ${IIT_SOURCES}/robotology-superbuild/build/install/share/robotology-superbuild/setup.sh
    export SUPERBUILD_SOURCED=1
fi

# Load the ROS environment
if [ -e /opt/ros/$ROS_DISTRO/setup.bash ] ; then
    source /opt/ros/$ROS_DISTRO/setup.bash
fi

# Load the gazebo environment
if [ -e /usr/share/gazebo/setup.sh ] ; then
    source /usr/share/gazebo/setup.sh
fi

# Docker configures the path of the root user. Set here the PATH also for the runtime user
export PATH=${IIT_PATH:+${IIT_PATH}:}${PATH}:/opt/qtcreator/bin

# Enable ccache for the user created during runtime
if [ -x $(which ccache) ] ; then
	mkdir -p /home/${USERNAME}/.ccachebin
	chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ccachebin
	export PATH=/home/${USERNAME}/.ccachebin:/usr/lib/ccache:${PATH}
fi

# Set clang as default compiler
compiler.set clang${CLANG_VER%.*} >/dev/null

# Enable matlab
if [ -x "/usr/local/MATLAB/bin/matlab" ] ; then
	export PATH=${PATH}:/usr/local/MATLAB/bin
	export MATLABPATH=${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}/mex/:${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}/share/WB-Toolbox/:${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}/share/WB-Toolbox/images
	# https://github.com/robotology/WB-Toolbox#problems-finding-libraries-and-libstdc
	alias matlab="LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab"
	# Set the bindings up
	export MATLABPATH=${MATLABPATH}:${IIT_INSTALL}/matlab
fi

# Aliases
# =======

NANO_DEFAULT_FLAGS="-w -S -i -m -$"
CMAKE_DEFAULT_FLAGS="--warn-uninitialized -DCMAKE_EXPORT_COMPILE_COMMANDS=1"
alias nano='nano $NANO_DEFAULT_FLAGS'
alias nanos='nano $NANO_DEFAULT_FLAGS -Y sh'
alias cmake='cmake $CMAKE_DEFAULT_FLAGS'
alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
if [ -e $(which pygmentize) ] ; then
	alias ccat='pygmentize -g'
	alias lesc='LESS="-R" LESSOPEN="|pygmentize -g %s" less'
	export LESS='-R'
	export LESSOPEN='|pygmentize -g %s'
fi
if [ -e $(which valgrind) ] ; then
	alias valgrind-xml='valgrind --xml=yes --xml-file=/tmp/valgrind.log'
	if [ -e $(which colour-valgrind) ] ; then
		alias valgrind='colour-valgrind'
	fi
fi
if [ -e $(which colordiff) ] ; then
	alias diff='colordiff'
fi
if [ -e $(which octave) ] ; then
	OCTAVE_BINDINGS_ROOT="${IIT_INSTALL}/octave"
	OCTAVE_BINDINGS_DIRS=""
	for extra_bindings_dir in ${OCTAVE_BINDINGS_ROOT}/+* ; do
		if [ -d ${extra_bindings_dir} ] ; then
			OCTAVE_BINDINGS_DIRS+="-p ${extra_bindings_dir} "
		fi
	done
	alias octave='octave -p ${OCTAVE_BINDINGS_ROOT} ${OCTAVE_BINDINGS_DIRS}'
fi
if [ -e $(which gazebo) ] ; then
	alias gazebo='gazebo -u'
fi
