#!/bin/sh
set -e
#set -x
for slave in `cat slaves.txt | egrep -v 'osx|win'`
do
    # Replace the ls command with whatever dangerous thing you had in mind
    if ssh buildbot@${slave} ls /etc/apt/sources.list.d | grep 'buildhost4' && ssh buildbot@${slave} ls /etc/apt/sources.list.d | egrep 'buildhost5'
    then
	    echo BAD: $slave
	    ssh $slave sudo rm '/etc/apt/sources.list.d/buildhost4*'
    fi
done
