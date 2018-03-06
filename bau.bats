#!/usr/bin/env bats

SUDO=sudo
case $OS in
Windows_NT) SUDO="" ;;
esac

@test "bau-smoke" {
  ./bau -v --help
  ./bau -v --version
  ./bau -v list | grep package
}

@test "bau-trickle" {
  if test -d /etc/apt/sources.list.d
  then
    $SUDO rm -rf sources.list.d.old.bautest
    $SUDO cp -a /etc/apt/sources.list.d sources.list.d.old.bautest
  fi

  # Get access to uncommitted obs and obs_funcs.sh
  PATH="$(pwd):$PATH"

  rm -rf bautest.tmp
  mkdir bautest.tmp
  cd bautest.tmp
   uberbau clone depdemo-particle
    cd depdemo-particle
    bau -v all --lprojects depdemo-proton
    cd ..
   cd ..
  rm -rf bautest.tmp

  pwd
  if test -d sources.list.d.old.bautest
  then
    $SUDO mv /etc/apt/sources.list.d /etc/apt/sources.list.d.old.$$
    $SUDO mv sources.list.d.old.bautest /etc/apt/sources.list.d
    $SUDO apt-get update
  fi
}

