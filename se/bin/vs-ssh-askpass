#!/usr/bin/env sh
#-------------------------------------------------
VS_LAUNCH_BIN_NAME="`basename \"$0\"`"
VS_LAUNCH_BIN_PATH="`dirname \"$0\"`"
VS_LAUNCH_BIN_PATH="`( cd \"$VS_LAUNCH_BIN_PATH\" && pwd )`"

# make sure we found the actual path
if [ -z "$VS_LAUNCH_BIN_PATH" ] ; then
  echo "Could not find directory path for $0"
  exit 1
fi

# make sure that 'vs' is not a symbolic link elsewhere
while ([ -L "$VS_LAUNCH_BIN_PATH/$VS_LAUNCH_BIN_NAME" ]) 
do
  VS_LAUNCH_LINKED_NAME="`readlink \"$VS_LAUNCH_BIN_PATH/$VS_LAUNCH_BIN_NAME\"`"
  if [ -z "$VS_LAUNCH_LINKED_NAME" ] ; then
    break
  else
    VS_LAUNCH_BIN_NAME="`basename \"$VS_LAUNCH_LINKED_NAME\"`"
    VS_LAUNCH_BIN_PATH="`dirname \"$VS_LAUNCH_LINKED_NAME\"`"
  fi
done

# prepend our bin directory to the dynamic library path
VSLICK_ORIG_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export VSLICK_ORIG_LD_LIBRARY_PATH
LD_LIBRARY_PATH=$VS_LAUNCH_BIN_PATH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

# make sure that Qt does not try to load plugins from la-la-land
VSLICK_ORIG_QT_PLUGIN_PATH=$QT_PLUGIN_PATH
export VSLICK_ORIG_QT_PLUGIN_PATH
QT_PLUGIN_PATH=
export QT_PLUGIN_PATH

# If there's no dbus session information, supply an address that is bad,
# but allows the subsystems that depend on it to fail gracefully, rather than
# just aborting the init.
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]
then
    export DBUS_SESSION_BUS_ADDRESS="abstract=/tmp/none-such-$$"
fi

# launch SlickEdit or vsdiff
if [ "$VS_LAUNCH_BIN_NAME" = "launch_vs.sh" ]; then
  exec "$VS_LAUNCH_BIN_PATH/vs_exe" "$@"
else
  exec "$VS_LAUNCH_BIN_PATH/$VS_LAUNCH_BIN_NAME"_exe "$@"
fi

