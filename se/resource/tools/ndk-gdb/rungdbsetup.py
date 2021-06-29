# Calls ndk-gdb in such a way that it performs all of the setup
# for remote debugging, but does not start the gdb client. Assumes the 
# PYTHONPATH has already been set up so we can load the NDK provided 
# libraries.
from tempfile import gettempdir
from time import sleep
import os
import sys
import gdbrunner

def script_path():
  return os.path.join(gettempdir(), 'ndkgdbscript')

def save_script(gdb_path, gdb_commands, gdb_flags = None, *rest):
  fh = open(script_path(), 'w')
  skipping_py = False
  for x in gdb_commands.splitlines():
    if skipping_py:
      if x == 'end':
        skipping_py = False
      continue
    else:
      if x == 'python':
        # Skip python section - we don't want to 
        # automatically connect to the remote.
        skipping_py = True
        continue

      fh.write(x)
      fh.write('\n')

  fh.close()
  print('Wrote GDB script file.')

# Patch so trying to start the gdb client just saves the
# gdb command list.  SlickEdit will connect its own client to 
# the remote gdbserver session.
gdbrunner.start_gdb = save_script

ndkgdb = __import__('ndk-gdb')
ndkgdb.main()
sf = script_path()
while os.path.exists(sf):
  sleep(2)
print('Script file removed, done.')

