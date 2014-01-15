#

source ~/.profile

echo -ne "\e]1;[zsh] `hostname`\a" # tab title
echo -ne "\e]2;[zsh] `hostname`\a" # window title

setopt prompt_subst

autoload -Uz vcs_info && vcs_info
zstyle ':vcs_info:*' formats "$(print '%{\e[1;37m%}|')\
$(print '%{\e[38;5;45m%}%s%{\e[1;37m%}:%{\e[38;5;2m%}%b%{\e[0m%}')"
zstyle ':vcs_info:*' actionformats "$(print '%{\e[1;37m%}|')\
$(print '%{\e[38;5;45m%}%s%{\e[1;37m%}:%{\e[38;5;2m%}%b%')\
$(print '%{\e[1;37m%}:%{\e[38;5;46m%}%b%{\e[0m%}')"
precmd () { vcs_info }

export PROMPT="$(print '%{\e[1;37m%}[%{\e[38;5;192m%}%/')\
$(print '${vcs_info_msg_0_}%{\e[1;37m%}] ')\
$(print '%{\e[0m%}-%{\e[1;37m%}%n%{\e[0m%}- ')\
$(print '%1(j.%{\e[38;5;185m%}|%j|%{\e[1;37m%}.)')\
$(print '%{\e[38;5;22m%}>')\
$(print '%{\e[38;5;34m%}>')\
$(print '%{\e[38;5;46m%}>')\
$(print '%{\e[0m%}') "
#$(print '%{\e[38;5;16m%}>')\
#$(print '%{\e[38;5;28m%}>')\
#$(print '%{\e[38;5;40m%}>')\

export PROMPT2="$(print '%{\e[1;37m%}[%{\e[38;5;192m%}%/')\
$(print '${vcs_info_msg_0_}%{\e[1;37m%}] ')\
$(print '%{\e[0m%}-%{\e[1;37m%}%n%{\e[0m%}- ')\
$(print '%1(j.%{\e[38;5;192m%}|%j|%{\e[1;37m%}.)')\
$(print '%{\e[38;5;22m%}>')\
$(print '%{\e[38;5;28m%}>')\
$(print '%{\e[38;5;34m%}>')\
$(print '%{\e[38;5;33m%}') %_ \
$(print '%{\e[38;5;34m%}>')\
$(print '%{\e[38;5;40m%}>')\
$(print '%{\e[38;5;46m%}>')\
$(print '%{\e[0m%}') "

export RPROMPT="$(print '[%(?.%{\e[1;37m%}%T%{\e[0m%}. %{\e[38;5;203m%}%?%{\e[0m%} )]')"
#export RPROMPT="$(print '[ %{\e[1;37m%}%(?.%T.%?)%{\e[0m%} ]')"
#export RPROMPT=$'%(?..[ %B%?%b ])'

export LC_ALL=zh_TW.UTF-8
export LANG=$LC_ALL
export EDITOR="vim"
export GREP_OPTIONS='--color=auto'
export HISTSIZE=1000
export SAVEHIST=1000
export HISTFILE=~/.history
export JS_CMD="js"

#export LSCOLORS=ExFxCxdxBxegedabagacad
LS_COLORS=''
LS_COLORS=$LS_COLORS:'no=0'           # Normal text       = Default foreground  
LS_COLORS=$LS_COLORS:'fi=0'           # Regular file      = Default foreground
LS_COLORS=$LS_COLORS:'di=38;5;27'       # Directory         = Bold, Blue
LS_COLORS=$LS_COLORS:'ln=01;36'       # Symbolic link     = Bold, Cyan
LS_COLORS=$LS_COLORS:'pi=33'          # Named pipe        = Yellow
LS_COLORS=$LS_COLORS:'so=01;35'       # Socket            = Bold, Magenta
LS_COLORS=$LS_COLORS:'do=01;35'       # DO                = Bold, Magenta
LS_COLORS=$LS_COLORS:'bd=01;37'       # Block device      = Bold, Grey
LS_COLORS=$LS_COLORS:'cd=01;37'       # Character device  = Bold, Grey
LS_COLORS=$LS_COLORS:'ex=35'          # Executable file   = Light, Blue
LS_COLORS=$LS_COLORS:'*FAQ=31;7'      # FAQs              = Foreground Red, Background Black
LS_COLORS=$LS_COLORS:'*README=33;7'   # READMEs           = Foreground Red, Background Black
LS_COLORS=$LS_COLORS:'*INSTALL=31;7'  # INSTALLs          = Foreground Red, Background Black
LS_COLORS=$LS_COLORS:'*.sh=47;31'     # Shell-Scripts     = Foreground White, Background Red
LS_COLORS=$LS_COLORS:'*.vim=35'       # Vim-"Scripts"     = Purple
LS_COLORS=$LS_COLORS:'*.swp=00;44;37' # Swapfiles (Vim)   = Foreground Blue, Background White
LS_COLORS=$LS_COLORS:'*.sl=30;33'     # Slang-Scripts     = Yellow
LS_COLORS=$LS_COLORS:'*,v=5;34;93'    # Versioncontrols   = Bold, Yellow
LS_COLORS=$LS_COLORS:'or=01;05;31'    # Orphaned link     = Bold, Red, Flashing
LS_COLORS=$LS_COLORS:'*.c=1;33'       # Sources           = Bold, Yellow
LS_COLORS=$LS_COLORS:'*.C=1;33'       # Sources           = Bold, Yellow
LS_COLORS=$LS_COLORS:'*.h=1;33'       # Sources           = Bold, Yellow
LS_COLORS=$LS_COLORS:'*.cc=1;33'      # Sources           = Bold, Yellow
LS_COLORS=$LS_COLORS:'*.awk=1;33'     # Sources           = Bold, Yellow
LS_COLORS=$LS_COLORS:'*.pl=1;33'      # Sources           = Bold, Yellow
LS_COLORS=$LS_COLORS:'*.jpg=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.jpeg=1;32'    # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.JPG=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.gif=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.png=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.jpeg=1;32'    # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.ppm=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.pgm=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.pbm=1;32'     # Images            = Bold, Green
LS_COLORS=$LS_COLORS:'*.tar=31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.tgz=1;31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.gz=1;31'        # Archive           = Red
LS_COLORS=$LS_COLORS:'*.xz=1;31'        # Archive           = Red
LS_COLORS=$LS_COLORS:'*.zip=31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.sit=31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.lha=31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.lzh=31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.arj=31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.bz2=1;31'       # Archive           = Red
LS_COLORS=$LS_COLORS:'*.html=36'      # HTML              = Cyan
LS_COLORS=$LS_COLORS:'*.htm=1;34'     # HTML              = Bold, Blue
LS_COLORS=$LS_COLORS:'*.php=1;45'     # PHP               = White, Cyan
LS_COLORS=$LS_COLORS:'*.doc=1;34'     # MS-Word *lol*     = Bold, Blue
LS_COLORS=$LS_COLORS:'*.txt=0'        # Plain/Text        = Default Foreground
LS_COLORS=$LS_COLORS:'*.o=1;36'       # Object-Files      = Bold, Cyan
LS_COLORS=$LS_COLORS:'*.a=1;36'       # Shared-libs       = Bold, Cyan
export LS_COLORS

# colorful man page
#export PAGER="`which less` -s"
#export BROWSER="$PAGER"
#export LESS_TERMCAP_mb=$'\E[38;5;167m'
#export LESS_TERMCAP_md=$'\E[38;5;39m'
#export LESS_TERMCAP_me=$'\E[38;5;231m'
#export LESS_TERMCAP_se=$'\E[38;5;231m'
#export LESS_TERMCAP_so=$'\E[38;5;167m'
#export LESS_TERMCAP_ue=$'\E[38;5;231m'
#export LESS_TERMCAP_us=$'\E[38;5;167m'

#setopt correctall
setopt append_history
setopt extended_history
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt no_hist_beep
setopt hist_save_no_dups
setopt noflowcontrol                  #no flow control enable keybind for ^Q
#setopt menu_complete

autoload -U compinit
compinit

zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
zstyle ':completion:*' list-colors $LS_COLORS
#zstyle ':completion:*' special-dirs ..

# git flow
# http://github.com/nvie/git-flow-completion
# source ~/.git-flow-completion.zsh

zle_highlight=(region:bg=magenta special:bold isearch:underline)

#bindkey -v                               # vi mode
bindkey -e                               # emacs mode
bindkey "\e[1~" beginning-of-line        # Home
bindkey "\e[7~" beginning-of-line        # Home rxvt
bindkey "\e[2~" overwrite-mode           # Ins
bindkey "\e[3~" delete-char              # Delete
bindkey "\e[4~" end-of-line              # End
bindkey "\e[8~" end-of-line              # End rxvt
bindkey "\e[5~" history-search-backward  # PageUp
bindkey "\e[6~" history-search-forward   # PageDown
bindkey "^Q" push-line
bindkey "^G" get-line
bindkey "^Z" undo
#bindkey "^Y" vi-undo-change
bindkey "^Xc" copy-region-as-kill
bindkey "^Xx" kill-region

expand-to-home-or-insert () {
  if [ "$LBUFFER" = "" -o "$LBUFFER[-1]" = " " ]; then
    LBUFFER+="~/"
  else
    zle self-insert
  fi
}
zle -N expand-to-home-or-insert
bindkey "\\"  expand-to-home-or-insert

os=`uname`

alias vi="vim"
alias vim="vim -p"
alias df="df -h"
if [ $os = "Darwin" ]; then
    alias ls="ls -G"
else
    alias ls="ls --color"
fi
alias ll="ls -al"
alias l="ls -a"
alias cls="clear"
alias clc="clear"
alias g='grep'
alias :q='exit'
alias :Q='exit'
alias vf="cd"
alias ~="cd ~"
alias ..="cd .."
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../../..'
alias -g ......='../../../../../..'
alias -g .......='../../../../../../..'


#autojump
#Copyright Joel Schaerer 2008, 2009
#This file is part of autojump

#autojump is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#autojump is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with autojump.  If not, see <http://www.gnu.org/licenses/>.

#local data_dir=${XDG_DATA_HOME:-$([ -e ~/.local/share ] && echo ~/.local/share || echo ~)}
local data_dir=$([ -e ~/.local/share ] && echo ~/.local/share || echo ~)
if [[ "$data_dir" = "${HOME}" ]]
then
    export AUTOJUMP_DATA_DIR=${data_dir}
else
    export AUTOJUMP_DATA_DIR=${data_dir}/autojump
fi
if [ ! -e "${AUTOJUMP_DATA_DIR}" ]
then
    mkdir "${AUTOJUMP_DATA_DIR}"
    mv ~/.autojump_py "${AUTOJUMP_DATA_DIR}/autojump_py" 2>>/dev/null #migration
    mv ~/.autojump_py.bak "${AUTOJUMP_DATA_DIR}/autojump_py.bak" 2>>/dev/null
    mv ~/.autojump_errors "${AUTOJUMP_DATA_DIR}/autojump_errors" 2>>/dev/null
fi

function autojump_preexec() {
    { (autojump -a "$(pwd -P)"&)>/dev/null 2>>|${AUTOJUMP_DATA_DIR}/autojump_errors ; } 2>/dev/null
}

typeset -ga preexec_functions
preexec_functions+=autojump_preexec

alias jumpstat="autojump --stat"

function j { local new_path="$(autojump $@)";if [ -n "$new_path" ]; then echo -e "\\033[31m${new_path}\\033[0m"; cd "$new_path";fi }


alias updatedemo-sb="ssh aps_user@50.18.186.203 'cd ~/workspace/scene-builder;git pull'"
alias updatedemo-common="ssh aps_user@50.18.186.203 'cd ~/workspace/scene-builder;git pull'"

function check_compression {
    local unzipped=`curl "$1" --silent --write-out "%{size_download}"  --output /dev/null`
    local zipped=`curl -H "Accept-Encoding: gzip,deflate" "$1" --silent --write-out "%{size_download}" --output /dev/null`
    echo "unzipped size: $unzipped, zipped size: $zipped"
}

[[ -s "/Users/othree/.rvm/scripts/rvm" ]] && source "/Users/othree/.rvm/scripts/rvm"

