#!/bin/sh
set -ex
MASTER=${MASTER:-buildhost5.oblong.com}
WORKERPW=${WORKERPW:-$(cat secrets.dir/my-buildbot-pw)}

SRC=$(dirname $0)
SRC=$(cd $SRC; pwd)

do_install() {
  if test -f /etc/issue
  then
    sudo apt install -y python3-buildbot-worker
  else
    pip3 install buildbot-worker
  fi
}

do_init() {
  mkdir ~/slave-state
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
    sudo apt remove -y --purge python3-buildbot-worker
  else
    pip3 uninstall buildbot-worker
  fi
}

case "$1" in
    install)   do_install ;;
    init)      do_init ;;
    run)       do_run ;;
    uninit)    do_uninit ;;
    uninstall) do_uninstall ;;
    *) usage; bs_abort "bad arg $1"  ;;
esac
