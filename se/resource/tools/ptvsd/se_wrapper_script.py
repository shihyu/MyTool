# Wrapper script that gates debuggee from running till after 
# all configuration is done.  Works around pydevd starting the debuggee
# after the attach, instead of waiting for the ConfigurationDone message.
# Shipped PTVSD version: 4.3.2
import os
import sys
import runpy
from time import sleep
import socket

configDone = False
waiter = None
try:
  waiter = socket.socket();
  waiter.bind(('127.0.0.1', 28546))
  waiter.listen(1)
  waiter.settimeout(30)
  conn, addr = waiter.accept()
  conn.close()

  configDone=True
except:
  print('se_wrapper_script: falling back to config delay.')
finally:
  if waiter is not None:
    waiter.close()

if not configDone:
  # not great, but slightly better than erroring out if the port is not available.
  sleep(5)

script = sys.argv[1]
dir = os.path.dirname(script)
sys.path.insert(0, dir)
sys.argv = sys.argv[1:]
runpy.run_path(script, run_name = '__main__')
