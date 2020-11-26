#!/bin/bash

export AUTOSSH_POLL=60
export AUTOSSH_FIRST_POLL=30
export AUTOSSH_GATETIME=0
export AUTOSSH_DEBUG=1

if ping -c 1 168.95.1.1 >/dev/null 2>&1 ; then
    echo 'network ok!!' 
else
    echo 'network fail!!'
    exit 0
fi

result=`ps aux | grep -i "autossh -M" | grep -v "grep" | wc -l`
if [ $result -ge 1 ]
then
    echo 'autossh 3333 is running'
else
    echo 'Start autossh 3333'
	AUTOSSH_DEBUG=1 AUTOSSH_LOGFILE=/tmp/autossh.log  AUTOSSH_POLL=5 autossh -M 65432 -NfR 3333:localhost:22 -i /home/shihyu/test/test_id_rsa yaoshihyu@35.236.179.104
    #AUTOSSH_DEBUG=1 AUTOSSH_LOGFILE=/tmp/autossh.log  AUTOSSH_POLL=5 autossh -M 65432 -NfR 3333:localhost:22 yaoshihyu@35.236.179.104
fi
