#!/bin/bash
# --- cdots.sh -------------------------------------------------------
# Change directory back - 1-7 times - and forth with TAB-completion.
# Copyright (C) 2007-2008  Freddy Vulto
# Version: cdots-1.2.1
# Usage: .. [dir]
#        ... [dir]
#        .... [dir]
#        ..... [dir]
#        ...... [dir]
#        ....... [dir]
#        ........ [dir]
##
# Arguments: [dir]   Directory to go forth - down the directory tree
#
# Example:   $/usr/local/share> ... sh[TAB]
#            $/usr/share>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
# MA  02110-1301, USA
#
# The latest version of this software can be obtained here:
# http://www.fvue.nl/cdots/


#--- _cdots() --------------------------------------------------------
# TAB completion for the .. ... .... etc commands
# @see cdots()
function _cdots() {
        # ':1' = Ignore dot at pos 0
    local dots=${COMP_WORDS[COMP_CWORD-1]:1} IFS=$'\n' i j=0
        #      +-----------2---------+ : Remove trailing `/*'s from PWD
        #      |     +-------1------+| : Replace every `.' with `/*'
    local dir="${PWD%${dots//\./\/\*}}/"
        # If first `compgen' returns no matches, try second `compgen'
        # which allows for globbing characters
    for i in $(
        compgen -d -- "$dir${COMP_WORDS[COMP_CWORD]}" ||
        compgen -d -X '!'"$dir${COMP_WORDS[COMP_CWORD]}*" -- $dir
    ); do
            #  If i not dir in current dir, append extra slash '/'
            #  NOTE: With bash > v2, if i is also dir in current dir, 
            #+       'complete -o filenames' automatically appends 
            #+       slash '/'
        (( $BASH_VERSINFO == 2 )) || [ ! -d ${i#$dir} ] && i="$i/"
        COMPREPLY[j++]="${i#$dir}"
    done
} # _cdots()


#--- cdots() ---------------------------------------------------------
# Change directory to specified directories back, and forth
# @param $1 string   Directory back
# @param $2 string   Directory forth
# @see _cdots() for TAB-completion
function cdots() {
    # If dir can't be found, try globbing with `eval'
    [ -d "$1$2" ] && cd "$1$2" || eval cd "$1$2"
} # cdots()


    # Define aliases .. ... .... etc, up to depth seven
    # NOTE: Functions are not defined directly as .. ... .... etc, 
    #       because these are not valid identifiers under `POSIX'
cdotsAlias=.; cdotsAliases=; cdotsDepth=7; cdotsDir=
while ((cdotsDepth--)); do
    cdotsAlias=$cdotsAlias.; cdotsDir=$cdotsDir../
    alias $cdotsAlias="cdots $cdotsDir"
    cdotsAliases="$cdotsAliases $cdotsAlias"
done
    # Set completion of aliases .. ... .... etc to _cdots()
    # -o filenames: Escapes whitespace
complete -o filenames -o nospace -F _cdots $cdotsAliases
unset -v cdotsDepth cdotsAlias cdotsAliases cdotsDir
