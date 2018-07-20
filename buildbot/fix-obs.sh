#!/bin/sh
# Do obs-related configuration for all slaves.
set -e

# Do whatever it takes to get up to date obs on the remote machines.
# Note: developers use apt or brew packages on ubuntu and mac, but buildslaves just install obs from git.

for slave in `./slaves.sh`
do
    echo ===== $slave ====
    case $slave in
    *pi3*)
        tries=4
        while test $tries -gt 1 && ! ssh -o StrictHostKeyChecking=no buildbot@${slave} "rm -f .obs/timestamp; sudo classic sh .obs/obs/buildbot/bootstrap-obs.sh || true"
        do
             sleep 5
             tries=$(expr $tries - 1)
        done
        ;;
    *osx*)
        tries=4
        while test $tries -gt 1 && ! ssh -o StrictHostKeyChecking=no buildbot@${slave} "PATH=\$PATH:/usr/local/bin; brew uninstall -f obs; rm -f ~/.obs/timestamp; sh .obs/obs/buildbot/bootstrap-obs.sh"
        do
             sleep 5
             tries=$(expr $tries - 1)
        done
        ;;
    *)
        tries=4
        while test $tries -gt 1 && ! ssh -o StrictHostKeyChecking=no buildbot@${slave} "sh .obs/obs/buildbot/bootstrap-obs.sh"
        do
             sleep 5
             tries=$(expr $tries - 1)
        done
        ;;
    esac
done

echo done
