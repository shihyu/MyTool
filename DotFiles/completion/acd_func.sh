# do ". acd_func.sh"
# acd_func 1.0.5, 10-nov-2004
# petar marinov, http:/geocities.com/h2428, this is public domain
# ################################################################################################
# Man page
# ################################################################################################
# NAME
#
#	acd_func.sh -- extends bash's CD to keep, display and access history of visited directory names
#
# SYNOPSIS
#
#	source acd_func.sh
#
# DESCRIPTION
#
#	This is a scripts which defines a CD replacement function in order to keep, display and access
#	history of visited directories. Normally the script will be sourced at the end of .bashrc.
#
#	cd --
#
#		Shows the history list of visited directories. 
#		The list shows the most recently visited names on the top.
#
#	cd -NUM
#
#		Changes the current directory with the one at position NUM in the history list. 
#		The directory is also moved from this position to the top of the list.
# ################################################################################################

cd_func ()
{
	local x2 the_new_dir adir index
	local -i cnt

	if [[ $1 ==  "--" ]]; then
		dirs -v
		return 0
	fi

	the_new_dir=$1
	[[ -z $1 ]] && the_new_dir=$HOME

	if [[ ${the_new_dir:0:1} == '-' ]]; then
		#
		# Extract dir N from dirs
		index=${the_new_dir:1}
		[[ -z $index ]] && index=1
		adir=$(dirs +$index)
		[[ -z $adir ]] && return 1
		the_new_dir=$adir
	fi

	#
	# '~' has to be substituted by ${HOME}
	[[ ${the_new_dir} == '~' ]] && the_new_dir="${HOME}" # Bugfix by Kent
	[[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

	#
	# Now change to the new dir and add to the top of the stack
	pushd "${the_new_dir}" > /dev/null
	[[ $? -ne 0 ]] && return 1
	the_new_dir=$(pwd)

	#
	# Trim down everything beyond 10th entry
	popd -n +10 2>/dev/null 1>/dev/null

	#
	# Remove any other occurence of this dir, skipping the top of the stack
	for ((cnt=1; cnt <= 10; cnt++)); do
		x2=$(dirs +${cnt} 2>/dev/null)
		[[ $? -ne 0 ]] && return 0
		[[ ${x2} == '~' ]] && x2="${HOME}" # Bugfix by Kent
		[[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
		if [[ "${x2}" == "${the_new_dir}" ]]; then
			popd -n +$cnt 2>/dev/null 1>/dev/null
			cnt=cnt-1
		fi
	done

	return 0
}

# Kent, comment this line due to existing "function cd()" in .bashrc
#alias cd=cd_func

if [[ $BASH_VERSION > "2.05a" ]]; then
	# 'Alt+d' shows the menu (d for dirs)
	bind -x '"\ed":"cd_func -- ;"'
fi

