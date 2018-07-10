#!/bin/sh
# Copyright Oblong 2012-2018
# Sets up a buildbot master

usage() {
cat << _EOF_
Convenience script for buildbot masters; handy place to hide nasty details and enforce conventions.
Usage:
    sh bmaster.sh install
    sh bmaster.sh [init|check|uninit]
    sh bmaster.sh uninstall
_EOF_
}

# Where this script lives
SRC=`dirname $0`
# Get an absolute directory (for the case where it's run with 'sh bmaster.sh')
SRC=`cd $SRC; pwd`

. $SRC/../obs_funcs.sh
_os=$(bs_detect_os)

set -x
set -e

# We use --user installed python
PATH=$HOME/.local/bin:$PATH

# In case we want to add support for non-linux masters later
BUILDUSER=$LOGNAME
BUILDUSERHOME=$HOME

# Working area; holds all the state of the installed buildbot master instances
TOP=$BUILDUSERHOME/master-state

install_buildbot() {
    git --version || bs_abort "need git"
    patch --version || bs_abort "need patch"
    test -x "`which unzip 2>/dev/null`" || bs_abort "need unzip"
    wget --version > /dev/null 2>&1 || bs_abort "need wget"
    pip3 install --user buildbot-www buildbot-waterfall-view buildbot-console-view buildbot-grid-view txrequests anybox.buildbot.capability
}

init_master() {
    if test -d $TOP
    then
        bs_abort "$TOP already exists"
    fi
    mkdir -p $TOP
    buildbot create-master --relocatable $TOP
    install_service
}

check_master() {
    buildbot checkconfig $TOP
}

# Graceful shutdown
stop_master() {
    buildbot stop --clean $TOP
}

# Graceful restart
restart_master() {
    buildbot reload --clean $TOP
}

# Run service in foreground with no extra processes (e.g. subshells) in memory
do_run() {
    buildbot start --nodaemon $TOP
}

uninit_master() {
    uninstall_service $1 || true
    stop_master
    rm -rf $TOP
}

# Add this project's buildmaster to the system service manager.
install_service() {
    (
        cat  <<_EOF_
[Unit]
Description=BuildBot master
After=network-started.target

[Service]
Type=simple
User=buildbot
Group=buildbot
ExecStart=$SRC/bmaster.sh run
ExecStop=$SRC/bmaster.sh stop

[Install]
WantedBy=multi-user.target
_EOF_
    ) | sudo tee /lib/systemd/system/buildmaster.service
    sudo systemctl enable buildmaster
}

uninstall_service() {
    (
    sudo systemctl stop buildmaster
    sudo systemctl disable buildmaster
    sudo rm /lib/systemd/system/buildmaster.service
    )
}

#--------------------------------------------------------------------------

uninstall() {
    rm -rf $TOP
}

case "$1" in
    prereqs)   install_prereqs    ;;   # for testing
    install)   install_buildbot   ;;
    init)      init_master "$2"   ;;
    check)     check_master "$2"  ;;
    run)       do_run "$2"        ;;
    stop)      stop_master "$2"   ;;
    restart)   restart_master "$2";;
    uninit)    uninit_master "$2" ;;
    uninstall) uninstall          ;;
    *) usage; bs_abort "bad arg $1"  ;;
esac
