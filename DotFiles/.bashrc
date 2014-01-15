# .bashrc

# If not running interactively, don't do anything.
# This snippet helps to fix scp, sftp "Received message too long" issue..
[ -z "$PS1" ] && return

# Source global definitions

[ -f /etc/bashrc ] && . /etc/bashrc
[ -f /etc/profile ] && . /etc/profile

infocmp screen-256color > /dev/null 2>&1
[ $? -eq 0 -a -n "$TMUX" ] && export TERM=screen-256color || export TERM=xterm-256color

export EDITOR=vim
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

dotfiles="$HOME/Repos/github-chenkaie/DotFiles"

exist () { type "$1" &> /dev/null; }
#######################
# JOB Related         #
#######################

#export MAKEINC=/home/project/makcomm
export LINTDIR=/usr/share/pclint
export MANSECT=8:2:1:3:4:5:6:7:9:0p:1p:3p:tcl:n:l:p:o

# GIT daily repo commit variable (A.K.A GIT Time Machine)
export GIT_MANAGED_DIRECTORY="$HOME/Project $HOME/ArmTools $HOME/Repos $HOME/practice $HOME/usr $HOME/makcomm-debug"

# Add new pkg search path by specifying below environment variable. (man pkg-config)
export PKG_CONFIG_PATH="$HOME/usr/lib/pkgconfig/"

###############################
# Different OS specific stuff #
###############################

OS=$(uname)             # for resolving pesky os differing switches

case $OS in
	Darwin|*BSD)
		# MacPorts stuff
		if [ -x /opt/local/bin/port ]; then
			export PATH=/opt/local/bin:/opt/local/sbin:$PATH
			export MANPATH=/opt/local/share/man:$MANPATH

			# bash_completion if installed
			if [ -x /opt/local/etc/bash_completion ]; then
				. /opt/local/etc/bash_completion
			fi
		fi

		# Homebrew stuff
		if [ -x /usr/local/bin/brew ]; then
			export PATH=$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:/usr/local/sbin:$PATH
			export MANPATH=/usr/local/share/man:$MANPATH

			# bash_completion if installed
			if [ -f `brew --prefix`/etc/bash_completion ]; then
				. `brew --prefix`/etc/bash_completion
			fi

			# brew_bash_completion.sh
			if [ -f `brew --prefix`/Library/Contributions/brew_bash_completion.sh ]; then
				. `brew --prefix`/Library/Contributions/brew_bash_completion.sh
			fi
		fi

		# PATH
		export PATH=$HOME/Tools:$HOME/Tools/subversion-scripts:$HOME/Tools/git-scripts:$HOME/usr/bin:$PATH
		# MANPATH
		export MANPATH=$HOME/usr/man:$HOME/usr/share/man:$MANPATH
		# PERL5LIB
		export PERL5LIB=$HOME/usr/lib/perl5/site_perl/5.10.1:$HOME/usr/lib/perl5/5.10.1:$PERL5LIB

		# Simple Ruby version management
		exist rbenv && eval "$(rbenv init -)"
		;;

	Linux)
		# enable color support of ls and also add handy aliases
		if [ "$TERM" != "dumb" ]; then
			eval `dircolors -b`
		fi

		# Note that, Ubuntu have been already done sourcing /etc/bash_completion in /etc/profile,
		# Source this file twice will cause user fail to login GNOME.
		# You can check this file ~/.xsession-errors to find out why you login GNOME failed.
		IsUbuntu=$(lsb_release -a | grep Ubuntu)
		# enable bash completion
		if [ -z "$IsUbuntu" ] && [ -f /etc/bash_completion ]; then
			. /etc/bash_completion
		fi
		# PATH
		export PATH=$HOME/hr:$HOME/perl5/bin:$HOME/Tools:$HOME/Tools/subversion-scripts:$HOME/Tools/git-scripts:$HOME/usr/bin:$HOME/usr/sbin:$PATH
		# MANPATH
		export MANPATH=$HOME/usr/man:$HOME/usr/share/man:$HOME/usr/cpan/share/man:$MANPATH

		# PERL5
        [ -s "$HOME/.perlbrew/etc/bashrc" ] && source "$HOME/.perlbrew/etc/bashrc"
		export PERL_CPANM_OPT="-l ~/usr"
		export PERL5LIB=$HOME/usr/lib/perl5:$HOME/perl5/lib/perl5:$PERL5LIB

		# Python
        [ -s "$HOME/.pythonbrew/etc/bashrc" ] && source "$HOME/.pythonbrew/etc/bashrc"
		;;

	*)
		echo "Your OS Type is : `uname -s`"
		# openbsd doesn't do much for color, some others may..
		export CLICOLOR=1
		;;
esac

#######################
# Alias               #
#######################

# enable color for LS
case $OS in
	Darwin|*BSD)
		export CLICOLOR=1
		export LSCOLORS=ExFxCxDxBxegedabagacad
		alias ls='ls -FG'
		# By installing homebrew: GNU coreutils, alias as Linux-way
		alias ls='ls -FN --color=auto --time-style=long-iso'
		;;
	Linux)
		alias ls='ls -FN --color=auto --time-style=long-iso'
		;;
esac

alias l='ls -FG'
alias ll='ls -al'                   # long list format
alias lk='ls -lk'                   # --block-size=1K
alias lt='ls -ltr'                  # sort by date (mtime)
alias lc='ls -ltcr'                 # sort by and show change time
alias la='ls -ltur'                 # sort by and show access time
alias lx='ls -lXB'                  # sort by extension
alias lz='ls -lSr'                  # sort by size
alias ld='ls -d */'                 # es only Dirs
alias l.='ls -dAFh .[^.]*'          # ls only Dotfiles
alias lst='ls -hFtal | grep $(date +%Y-%m-%d)' #ls Today

#alias tree='tree -Cs'              # nice alternative to 'ls'
alias vim='vim -X -p'
alias vi='vim'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias df='df -kTh'
alias ln='ln -i -n'
alias psg='ps -ef | grep $1'
alias h='history | grep $1'
alias j='jobs'
alias less='less -R --tabs=4'       # colorful 'less', tab stops = 4
alias more='less'
alias mkdir='mkdir -p -v'
alias reload='source ~/.bashrc'
alias wget='wget -c'
alias which='type -a'
alias quota='quota -vs'
alias grep='grep --color'
alias head='head -n $((${LINES:-12}-2))'      # As many as possible without scrolling
alias tail='tail -n $((${LINES:-12}-2)) -s.1' # Likewise, also more responsive -f
alias g='git'
exist hub && eval "$(hub alias -s)"

# have to check exist()
exist htop && alias top='htop'
alias xmllint='xmllint --noout'

#export GREP_OPTIONS="--exclude-dir=\*/.svn/\* --exclude=\*~ --exclude=\*.swp"
#alias wcgrep='wcgrep -inh --colour=auto' has been defined in wcgrep
alias mdiff='diff -ruN --exclude=.svn'
alias diff='colordiff.pl'

# Moving around & all that jazz
#alias cd='pushd > /dev/null'
#alias back='popd > /dev/null'
alias b='cd -' # back to $OLDPWD
alias cd..='cd ..'

alias path='echo -e ${PATH//:/\\n}'
alias perlpath='perl -le "print foreach @INC"'
# Generate Windows CIFS path prepend with Network Drive id: "Z:"
alias pwd-win='pwd | sed '"'"'s/\//\\/g'"'"' | sed '"'"'s/\(.*\)/Z:\1/'"'"''
# A simple python http file server
alias hfs='python -m SimpleHTTPServer 8080'
#
alias python='PYTHONSTARTUP=~/Tools/inpy python'

#Personal Help
alias l?='cat ~/.bashrc | grep "alias l.*=.ls" | grep ^a'
alias a?='alias'
alias f?='cat $dotfiles/.function.help'
alias dn='OPTIONS=$(\ls -F | grep /$); select s in $OPTIONS; do cd $PWD/$s; break;done'
#alias help='OPTIONS=$(\ls $dotfiles/.tips -F);select s in $OPTIONS; do less $dotfiles/.tips/$s; break;done'

#delete
alias del='mv --target-directory=$HOME/.Trash/'

#aliases and export for Project
alias pcd='cd ${PRODUCTDIR}'
alias icd='cd ${IMAGEDIR}'
alias scd='cd ${PRODUCTDIR}/build/scripts'
alias rcd='cd ${PRODUCTDIR}/release;pwd'
alias pd='echo ${PRODUCTDIR}'
alias rmrd='[ -n "$PRODUCTDIR" ] && cd ${PRODUCTDIR}/release; rm -rf app_cluster_Build/ flashfs/ rootfs/; cd -'

#make for fun
alias make='cmake'
alias m='make'
alias mc='m clean'
alias mca='m cleanall'
alias mi='m install'
alias mall='mca && m && mi'

#gcc
alias agcc='arm-linux-gcc -Wall -g3 -fno-omit-frame-pointer -fno-inline -Wcast-align -Wpadded -Wpacked -std=gnu99'
alias gcc='gcc -Wall -g3 -fno-omit-frame-pointer -fno-inline -Wcast-align -Wpadded -Wpacked -std=gnu99'
alias objdump='objdump -d -S -l -shrt'
alias gdb='gdb --command=$HOME/Repos/DotFiles/.gdbinit-7.3'
#alias strace='strace -f -v -x -s 128'

#Lint related
exist jsl  && alias jsl='jsl -conf ~/Tools/jsl.conf -process'
if exist lint ; then
	alias lint-gnu='lint ~/makcomm/env-vim.lnt'
	alias lint-gnu-xml='lint-gnu ~/makcomm/env-xml.lnt'
	alias lint-gnu-html='lint-gnu ~/makcomm/env-html.lnt'
	alias lint-arm='lint ~/makcomm/env-vim.lnt'
	alias lint-arm-xml='lint-arm ~/makcomm/env-xml.lnt'
	alias lint-arm-html='lint-arm ~/makcomm/env-html.lnt'
fi

# ccache & distcc
alias enjoy-ccache-distcc="source $HOME/Tools/use_distcc_ccache"

# enjoy proxy
alias enjoy-proxy="source $HOME/Tools/use_proxy"

#######################
# Bash SHell opts     #
#######################

#history control, ignorespace & ignoredups
export HISTCONTROL=ignoreboth
export HISTSIZE=100000
export HISTTIMEFORMAT="%Y-%m-%d_%H:%M:%S_%a  "
export HISTIGNORE="&:bg:fg:ll:h"

#Specify that it (Ctrl+D) must pressed twice to exit Bash
export IGNOREEOF=1

set -o noclobber
set -o notify
#Use a vi-style command line editing interface, enter by <Esc> or <C-[>
#Note that some emacs mode "C-x" prefix key binding are gone. $ bind -p | grep "C-x"
set -o vi

#set -o xtrace          # Useful for debuging.
#set +o OOXX            # Turn off OOXX

# Enable options:
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
shopt -s histappend
shopt -s no_empty_cmd_completion
shopt -s cdspell
shopt -s checkhash

#######################
# Default             #
#######################

# Define Colors {{{
TXTBLK="\[\033[0;30m\]" # Black - Regular
TXTRED="\[\033[0;31m\]" # Red
TXTGRN="\[\033[0;32m\]" # Green
TXTYLW="\[\033[0;33m\]" # Yellow
TXTBLU="\[\033[0;34m\]" # Blue
TXTPUR="\[\033[0;35m\]" # Purple
TXTCYN="\[\033[0;36m\]" # Cyan
TXTWHT="\[\033[0;37m\]" # White
BLDBLK="\[\033[1;30m\]" # Black - Bold
BLDRED="\[\033[1;31m\]" # Red
BLDGRN="\[\033[1;32m\]" # Green
BLDYLW="\[\033[1;33m\]" # Yellow
BLDBLU="\[\033[1;34m\]" # Blue
BLDPUR="\[\033[1;35m\]" # Purple
BLDCYN="\[\033[1;36m\]" # Cyan
BLDWHT="\[\033[1;37m\]" # White
UNDBLK="\[\033[4;30m\]" # Black - Underline
UNDRED="\[\033[4;31m\]" # Red
UNDGRN="\[\033[4;32m\]" # Green
UNDYLW="\[\033[4;33m\]" # Yellow
UNDBLU="\[\033[4;34m\]" # Blue
UNDPUR="\[\033[4;35m\]" # Purple
UNDCYN="\[\033[4;36m\]" # Cyan
UNDWHT="\[\033[4;37m\]" # White
BAKBLK="\[\033[40m\]"   # Black - Background
BAKRED="\[\033[41m\]"   # Red
BAKGRN="\[\033[42m\]"   # Green
BAKYLW="\[\033[43m\]"   # Yellow
BAKBLU="\[\033[44m\]"   # Blue
BAKPUR="\[\033[45m\]"   # Purple
BAKCYN="\[\033[46m\]"   # Cyan
BAKWHT="\[\033[47m\]"   # White
TXTRST="\[\033[0m\]"    # Text Reset
# }}}

# Git shell prompt
if [ "\$(type -t __git_ps1)" ]; then
	PROMPT_GIT='$(__git_ps1 "|'$BLDCYN'git'$TXTRST':%s")'
fi

# SVN shell prompt
# Ref: https://github.com/l0b0/tilde/blob/master/scripts/__svn_ps1.sh
__svn_ps1 ()
{
	svn info > /dev/null 2>&1 || return
	local result=$(
		svn info 2>/dev/null | \
		perl -ne 'print if s;^URL: .*?/((trunk)|(branches|tags)/([^/]*)).*;\2\4 ;')

	test -n "$result" || result="rev"
	local revision=$(svn info | grep Revision | awk '{print $2}')
	printf "${1:- (%s:%s)}" $result $revision
}

PROMPT_SVN='$(__svn_ps1 "|'$TXTCYN'svn'$TXTRST':%s-r%s")'

ps1_set()
{
	local prompt_char="$" separator="\n" prompt_time="" workding_dir="\w"

	# root privilege
	[ $UID -eq 0 ] && prompt_charclr=$TXTRED || prompt_charclr=$TXTWHT

	while [ $# -gt 0 ]; do
		local token="$1"; shift

		case "$token" in
		-x|--trace)
			export PS4="+ \${BASH_SOURCE} : \${FUNCNAME[0]:+\${FUNCNAME[0]}()} \${LINENO} > "
			[ "$1" == "off" ] && set +o xtrace || set -o xtrace
			shift
			;;
		-p|--prompt)
			prompt_char="$1"
			shift
			;;
		-s|--separator)
			separator="$1"
			shift
			;;
		-t|--time)
			prompt_time="$1"
			shift
			;;
		-w|--workingdir)
			workding_dir="$1"
			shift
			;;
		*)
			true # Ignore everything else.
			;;
		esac
	done
	PS1=$BLDBLK'['$prompt_time$TXTYLW'\u@''\h'$TXTWHT':'$TXTWHT'pts/\l'$TXTWHT${PROMPT_GIT}${PROMPT_SVN}$BLDBLK'$(ps1_counter)''] '$BLDWHT${workding_dir}${separator}${prompt_charclr}${prompt_char}$TXTWHT
}

#PS1=$TXTYLW'\u'$TXTWHT'@'${PROMPT_HOSTCOLOR}'\h'$TXTWHT':'$TXTGRN'\W'$TXTWHT${PROMPT_GIT}${PROMPT_SVN}$BLDBLK'$(ps1_counter)'$TXTGRN' >'$BLDGRN'>'$BLDWHT'> '$TXTWHT

case $OS in
	Darwin|*BSD)
		ps1_set -p "$TXTGRN>$BLDGRN>$BLDWHT>$TXTWHT " -t "\D{%H:%M:%S} "
		;;
	Linux)
		ps1_set -p "$TXTGRN>$BLDGRN>$BLDWHT>$TXTWHT " -s " " -w "\W"
		#ps1_set -p "$TXTGRNʕ•ᴥ•ʔ " -s " " -w "\W"
		;;
esac

# add for screen to dynamically update title
#PROMPT_COMMAND='echo -n -e "\033k\033\134"'


export PROMPT_COMMAND='history -a'

#export MANPAGER="most -s"
# Less Colors for Man Pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[01;44;33m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

#for X-Win32
#export DISPLAY="172.16.2.54:0:0"

# For all SSH (Reverse) Tunnel
case $OS in
	Darwin|*BSD)
		alias dd-wrt='ssh 192.168.1.1 -p2222 -lroot'
		#alias dd-wrt_rd1-2='ssh -L 7322:127.0.0.1:7322 192.168.1.1 -lroot -p2222'
		alias rd1-2='ssh 192.168.1.1 -p 7322'
		alias rd1-2-proxy='ssh -D 8080 192.168.1.1 -p7322'
		;;

	Linux)
		alias tunnel-mac='ssh -R 7322:rd1-2:22 chenkaie.no-ip.org'
		alias tunnel-ap='ssh -R 7322:rd1-2:22 chenkaie.no-ip.org -lroot -p2222'
		alias rd1wiki='ssh -R 8080:rd1-1:80 chenkaie.no-ip.org'
		alias dd-wrt='ssh chenkaie.no-ip.org -p2222 -lroot'
		#alias syncToRD1-3='rsync -r -a -v -e "ssh -l kent" --delete ~/Tools rd1-3:Tools'
		#alias syncToMac='rsync -r -a -v -e "ssh -l kent" --delete ~/Tools chenkaie.no-ip.org:RD1-2/Tools'
		;;
esac

# cool CMatrix
# exist cmatrix && cmatrix -ab

# funny stuff cowsay
# exist cowsay && echo "Welcome to $HOSTNAME" | cowsay -f default

# icat (Image cat) generated 256-color ascii images
if [ -d "$dotfiles/ascii-photo" ]; then
	filepath=($dotfiles/ascii-photo/*)
	nfile=${#filepath[@]}
	asciiwp="${filepath[RANDOM % nfile]}"
	cat $asciiwp
fi

# Completion support
source $dotfiles/completion/bash-completion/bash_completion
source $dotfiles/completion/svn_completion
source $dotfiles/completion/git-completion.bash
source $dotfiles/completion/git-prompt.sh
source $dotfiles/completion/cdargs-bash.sh
source $dotfiles/completion/cdots.sh
source $dotfiles/completion/git-flow-completion.bash
source $dotfiles/completion/acd_func.sh
source $dotfiles/completion/hub.bash_completion.sh
source $dotfiles/completion/bash_completion_tmux.sh


# make less more friendly for non-text input files, see lesspipe(1)
exist lesspipe && eval "$(lesspipe)"

#export LESS='-i -N -w  -z-4 -g -e -M -X -F -R -P%t?f%f :stdin .?pb%pb\%:?lbLine %lb:?bbByte %bb:-...'
export LESS='-FRXM --tabs=4 -i'

#######################
# Developer stuff     #
#######################

# Enable gcc colours, available since gcc 4.8.0
export GCC_COLORS=1

# print the corresponding error message
strerror() { python -c "import os,locale as l; l.setlocale(l.LC_ALL, ''); print os.strerror($1)"; }

#######################
# Terminal info       #
#######################
# Related CMD: tput, resize, reset, stty -a
COLUMNS=$(tput cols)
LINES=$(tput lines)

#######################
# Functions           #
#######################

# Easy extract
extract ()
{
	if [ -f $1 ] ; then
		case $1 in
		*.tar.bz2)   tar xvjf $1    ;;
		*.tar.gz)    tar xvzf $1    ;;
		*.bz2)       bunzip2 $1     ;;
		*.rar)       rar x $1       ;;
		*.gz)        gunzip $1      ;;
		*.tar)       tar xvf $1     ;;
		*.tbz2)      tar xvjf $1    ;;
		*.tgz)       tar xvzf $1    ;;
		*.zip)       unzip $1       ;;
		*.Z)         uncompress $1  ;;
		*.7z)        7z x $1        ;;
		*)           echo "don't know how to extract '$1'..." ;;
		esac
	else
		echo "'$1' is not a valid file!"
	fi
}

# easy compress - archive wrapper
compress ()
{
	if [ -n "$1" ] ; then
		FILE=$1
		case $FILE in
		*.tar) shift && tar cf $FILE $* ;;
		*.tar.bz2) shift && tar cjf $FILE $* ;;
		*.tar.gz) shift && tar czf $FILE $* ;;
		*.tgz) shift && tar czf $FILE $* ;;
		*.zip) shift && zip $FILE $* ;;
		*.rar) shift && rar $FILE $* ;;
		esac
	else
		echo "usage: compress <foo.tar.gz> ./foo ./bar"
	fi
}

# get current host related info
function sysinfo()
{
	echo -e "\nYou are logged on ${RED}$HOST"
	echo -e "\nAdditionnal information:$NC " ; uname -a
	echo -e "\n${RED}Users logged on:$NC " ; w -h
	echo -e "\n${RED}Current date :$NC " ; date
	echo -e "\n${RED}Machine stats :$NC " ; uptime
	echo -e "\n${RED}Memory stats :$NC " ; free
	echo -e "\n${RED}Local IP Address :$NC" ; myip
}

# Get IP (call with myip)
function myip
{
	myip=`elinks -dump http://checkip.dyndns.org:8245/`
	echo "${myip}"
}

encrypt () { gpg -ac --no-options "$1"; }
decrypt () { gpg --no-options "$1"; }

# finds directory sizes and lists them for the current directory
dirsize ()
{
	du -shx * .[a-zA-Z0-9_]* . 2> /dev/null | \
	egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
	egrep '^ *[0-9.]*M' /tmp/list
	egrep '^ *[0-9.]*G' /tmp/list
	rm -rf /tmp/list
}

# ls when cd, it's useful
function cd ()
{
	# replace "builtin cd" with cd_func() to enable "cd with history"
	if [ -n "$1" ]; then
		# builtin cd "$@"&& ls
		cd_func "$@" && [ "$1" != "--" ] && ls
	else
		# builtin cd ~&& ls
		cd_func ~ && ls
	fi
}

# swap() -- switch 2 filenames around
function swap()
{
	local TMPFILE=tmp.$$
	mv "$1" $TMPFILE
	mv "$2" "$1"
	mv $TMPFILE "$2"
}

# repeat() -- repeat a given command N times
function repeat()
{
	local i max
	max=$1; shift;
	for ((i=1; i <= max ; i++)); do
		eval "$@";
	done
}

# Find a file with pattern $1 in name and Execute $2 on it:
function fe()
{ wcfind . -type f -iname '*'${1:-}'*' -exec ${2:-ls} {} \;  ; }

# lazy gcc, default outfile: filename_prefix.out, eg: hello.c -> hello.out
function lgcc ()
{
	gcc -o ${1%.*}{.out,.${1##*.}} $2 $3 $4 $5
}

# lazy arm-linux-gcc, default outfile: filename_prefix.platform.out, eg: hello.c -> hello.arm.out
function lagcc ()
{
	# add '-a' for print all matching executables in PATH, not just the first to resolve ccache caused problem.
	platform=`\which -a arm-linux-gcc 2> /dev/null`
	case $platform in
		*vivaldi*)
			outfilesuffix="vivaldi"
			;;
		*bach*)
			outfilesuffix="bach"
			;;
		*haydn*)
			outfilesuffix="haydn"
			;;
		*mozart*)
			outfilesuffix="mozart"
			;;
		*montavista*)
			outfilesuffix="dm365"
			;;
		*arm*)
			outfilesuffix="arm"
			;;
		"")
		echo "[Error] arm-linux-gcc not found."
		return 1
		;;
	esac

	echo "[Info] You are building on ${outfilesuffix} platform."
	agcc -o ${1%.*}{.${outfilesuffix}.out,.${1##*.}} $2 $3 $4 $5
}

function ps1_counter()
{
	case $1 in *-h*) echo "(jobnum|dirnum)" ;; esac

	jobnum="$(jobs | wc -l | tr -d " ")"
	dirnum="$(dirs -v | tail -n 1 | awk '{print $1}')"

	if [ `expr $jobnum + $dirnum` -gt 0 ]; then
		echo -n " (${jobnum}/${dirnum})"
	fi
}

complete -c command see
function see()
{
	$EDITOR `\which $1`
}

# Returns the ASCII value of the first character of a string
ord() { printf "0x%x\n" "'$1"; }

# Returns a character from a specified ASCII value
chr() { printf $(printf '\\%03o\\n' "$1"); }

# vim: fdm=marker ts=4 sw=4:
