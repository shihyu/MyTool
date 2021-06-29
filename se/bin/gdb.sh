#!/usr/bin/env sh
#-------------------------------------------------
GDB_LAUNCH_BIN_NAME="`basename \"$0\"`"
GDB_LAUNCH_BIN_PATH="`dirname \"$0\"`"
GDB_LAUNCH_BIN_PATH="`( cd \"$GDB_LAUNCH_BIN_PATH\" && pwd )`"

# make sure we found the actual path
if [ -z "$GDB_LAUNCH_BIN_PATH" ] ; then
  echo "Could not find directory path for $0"
  exit 1
fi

# make sure that 'vs' is not a symbolic link elsewhere
while ([ -L "$GDB_LAUNCH_BIN_PATH/$GDB_LAUNCH_BIN_NAME" ]) 
do
  GDB_LAUNCH_LINKED_NAME="`readlink \"$GDB_LAUNCH_BIN_PATH/$GDB_LAUNCH_BIN_NAME\"`"
  if [ -z "$GDB_LAUNCH_LINKED_NAME" ] ; then
    break
  else
    GDB_LAUNCH_BIN_NAME="`basename \"$GDB_LAUNCH_LINKED_NAME\"`"
    GDB_LAUNCH_BIN_PATH="`dirname \"$GDB_LAUNCH_LINKED_NAME\"`"
  fi
done

# prepend our bin directory to the dynamic library path
LD_LIBRARY_PATH=$GDB_LAUNCH_BIN_PATH:$LD_LIBRARY_PATH:/usr/openwin/lib
export LD_LIBRARY_PATH

# Get path to toolconfig/vsdebug folder
TOOLCONFIG_VSDEBUG=$GDB_LAUNCH_BIN_PATH/../toolconfig/vsdebug

# Set up PYTHONHOME
PYTHONHOME="$GDB_LAUNCH_BIN_PATH/python2.7"
export PYTHONHOME

# launch gdb
"$GDB_LAUNCH_BIN_PATH/gdb" -data-directory "$TOOLCONFIG_VSDEBUG" "$@"

