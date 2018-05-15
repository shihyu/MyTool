#!/bin/bash
# Installation:
#   cd my_gitproject
#   wget -O pre-commit.sh http://tinyurl.com/mkovs45
#   ln -s ../../pre-commit.sh .git/hooks/pre-commit
#   chmod +x pre-commit.sh

OPTIONS="-A8 -t8 --lineend=linux"

RETURN=0
ASTYLE=$(which astyle)
if [ $? -ne 0 ]; then
	echo "[!] astyle not installed. Unable to check source file format policy." >&2
	exit 1
fi

FILES=`git diff --cached --name-only --diff-filter=ACMR | grep -E "\.(c|cpp|h)$"`
for FILE in $FILES; do
	$ASTYLE $OPTIONS < $FILE | cmp -s $FILE -
	if [ $? -ne 0 ]; then
		echo "[!] $FILE does not respect the agreed coding style." >&2
		RETURN=1
	fi
done

if [ $RETURN -eq 1 ]; then
	echo "" >&2
	echo "Make sure you have run astyle with the following options:" >&2
	echo $OPTIONS >&2
fi

