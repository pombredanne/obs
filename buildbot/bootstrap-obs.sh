#!/bin/sh
# Make sure obs is installed and up to date
# Doesn't check for multiple simultaneous runs, since we no longer run
# multiple containers sharing same home directory on build workers.
set -ex

if ! test -d ~/.obs
then
   mkdir ~/.obs
   cd ~/.obs
   git clone git@gitlab.oblong.com:platform/obs.git
else
   cd ~/.obs
fi

SUDO=
PREFIX=/usr
if test -f /etc/issue
then
   sudo=sudo
   sudo apt-get remove -y oblong-obs || true
fi
if test -d /Library
then
   PREFIX=/usr/local
fi

cd obs
(
   # Disable a2x so we don't waste 30 seconds formatting the man page
   rm -rf /tmp/obsfakebin
   mkdir /tmp/obsfakebin
   ln -s /bin/false /tmp/obsfakebin/a2x
   PATH=/tmp/obsfakebin:$PATH

   # Always update, 'cause the git repo may have been updated without a following install
   # Retry once, in case the network was temporarily down.
   git pull --ff-only || (sleep 10; git pull --ff-only)
   sudo make clean
   make obs bau bau.1 baugen.sh

   # On some systems, we installed it as root, tsk
   make PREFIX=$PREFIX uninstall-obs uninstall-bau 2>/dev/null || \
   sudo make PREFIX=$PREFIX PREFIX=$PREFIX uninstall-obs uninstall-bau || true

   $sudo make PREFIX=$PREFIX install-obs install-bau

   rm -rf /tmp/obsfakebin
)
cd ..

exit 0
