#!/bin/sh
# Do obs-related configuration for all slaves.
set -e

# Do whatever it takes to get up to date obs on the remote machines.
# Note: developers use apt or brew packages on ubuntu and mac, but buildslaves just install obs from git.

for slave in `./slaves.sh`
do
    echo ===== $slave ====
    ssh -o StrictHostKeyChecking=no buildbot@${slave} "cd src/obs && git checkout master && git pull --ff-only; cd ~/.obs/obs && git pull --ff-only" || true
done

echo done
