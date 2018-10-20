#!/bin/sh
set -e
#set -x
for slave in $(sh slaves.sh | egrep -v 'osx|win|mbp|pi3')
do
    echo -n "====  "
    ssh buildbot@${slave} 'hostname; grep . < /etc/issue; export DISPLAY=:0; glxinfo | egrep "renderer string|core profile version string"; xrandr | egrep " connected|\\*" ' || true
done
