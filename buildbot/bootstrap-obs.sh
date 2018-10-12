#!/bin/sh
# Make sure obs is installed and up to date
# Don't explode if called by multiple jobs at same time
set -ex

if ! test -d ~/.obs
then
   mkdir ~/.obs
   cd ~/.obs
   git clone git@gitlab.oblong.com:platform/obs.git
else
   cd ~/.obs

   # If timestamp exists but is too old, ignore
   if test -f timestamp
   then
       if test -d /Library
       then
          # BSD stat uses -f for format, %m for modification unix time
          birthday=$(stat -f %m timestamp)
       else
          # linux stat uses -c for format, %Y for modification unix time
          birthday=$(stat -c %Y timestamp)
       fi
       now=$(date +%s)
       age=$(expr $now - $birthday)
       if test $age -gt 40
       then
           echo "bootstrap-obs.sh: timestamp stale, ignoring"
           rm -f timestamp
       fi
   fi

   # Wait a while for other container to finish
   tries=30
   while test -f timestamp && test $tries -gt 0
   do
       echo "bootstrap-obs.sh: busy, waiting"
       sleep 5
       tries=$(expr $tries - 1)
   done
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

pingonce() {
   case "$OS" in
   Windows_NT) ping -n 1 $1;;
   *)          ping -c 1 $1;;
   esac
}

tries=6
while test $tries -gt 0 && ! pingonce oblong.com
do
   echo Waiting for DNS to finish
   sleep 5
   tries=$(expr $tries - 1)
done

touch timestamp
cd obs
(
   git fetch

   # Always update, 'cause the git repo may have been updated without a following install
   git pull --ff-only
   make clean
   make obs bau

   # On some systems, we installed it as root, tsk
   make PREFIX=$PREFIX uninstall-obs uninstall-bau 2>/dev/null || \
   sudo make PREFIX=$PREFIX PREFIX=$PREFIX uninstall-obs uninstall-bau || true

   $sudo make PREFIX=$PREFIX install-obs install-bau
)
cd ..
rm timestamp
exit 0
