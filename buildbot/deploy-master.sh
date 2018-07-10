#!/bin/sh
# Scary script to deploy buildbot master.
# Run this as user buildbot on the new machine.
# Assumes you've already run deploy-node.sh
set -e
set -x

suites="xenial bionic"

# install buildbot master
#sh bmaster.sh install

# install and configure reprepro
if ! fpm --version
then
    sudo apt install ruby; sudo gem install fpm
fi
sudo sh brepo.sh install
for codename in $suites
do
    bs_suites=$codename
    export bs_suites
    ./brepo.sh init rel-$codename
    ./brepo.sh init dev-$codename
done

sh bmaster.sh init

echo Now go set up the slaves
