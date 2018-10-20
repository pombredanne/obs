#!/bin/sh

usage() {
cat << _EOF_
Convenience script for buildbot slaves; handy place to hide nasty details and enforce conventions.
Usage:
    sh bslave.sh install
    sh bslave.sh init
    sh bslave.sh run
    sh bslave.sh uninit
    sh bslave.sh uninstall
_EOF_
}

MASTER=${MASTER:-buildhost5.oblong.com}
export MASTER
PATH=$HOME/.local/bin:$PATH

SRC=$(dirname $0)
SRC=$(cd $SRC; pwd)

do_install() {
  if test -f /etc/issue
  then
    if ! sudo apt install -y python3-buildbot-worker
    then
        sudo apt install -y python3-pip && pip3 install buildbot-worker
    fi
  else
    pip3 install buildbot-worker
  fi
}

do_init() {
  mkdir ~/slave-state
  # FIXME: should secrets.dir be named better and/or in $HOME?
  WORKERPW=${WORKERPW:-$(cat secrets.dir/my-buildbot-work-pw)}
  buildbot-worker create-worker -a file --umask=0o22 ~/slave-state $MASTER $(hostname) $WORKERPW
}

do_run() {
  buildbot-worker start --nodaemon ~/slave-state
}

do_uninit() {
  rm -rf ~/slave-state
}

do_uninstall() {
  if test -f /etc/issue
  then
    sudo apt remove -y --purge python3-buildbot-worker || pip3 uninstall buildbot-worker
  else
    pip3 uninstall buildbot-worker
  fi
}

set -ex
case "$1" in
    install)   do_install ;;
    init)      do_init ;;
    run)       do_run ;;
    uninit)    do_uninit ;;
    uninstall) do_uninstall ;;
    *) usage; echo "bad arg $1"; exit 1 ;;
esac
