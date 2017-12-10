#!/usr/bin/env bats

@test "bau-smoke" {
  ./bau -v --help
  ./bau -v --version
  ./bau -v list | grep package
}

@test "bau-trickle" {
  if ! test -d /Applications
  then
    sudo rm -rf sources.list.d.old.bautest
    sudo cp -a /etc/apt/sources.list.d sources.list.d.old.bautest
  fi

  rm -rf bautest.tmp
  mkdir bautest.tmp
  cd bautest.tmp
   ../uberbau clone depdemo-particle
    cd depdemo-particle
    PATH=$(cd ../..; pwd):$PATH ../../bau -v all --lprojects depdemo-proton
    cd ..
   cd ..
  rm -rf bautest.tmp

  pwd
  ls -l
  if test -d sources.list.d.old.bautest
  then
    sudo mv /etc/apt/sources.list.d /etc/apt/sources.list.d.old.$$
    sudo mv sources.list.d.old.bautest /etc/apt/sources.list.d
    sudo apt-get update
  fi
}

