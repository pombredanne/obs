#!/usr/bin/env bats

@test "uberbau-smoke" {
  if egrep '12.04|14.04' /etc/issue
  then
    echo "Skipping test on ubuntu 12.04 and 14.04 for now... it's fixable, but I'm not too motivated."
    return 0
  fi

  if ! test -d /Applications
  then
    sudo rm -rf sources.list.d.old
    sudo cp -a /etc/apt/sources.list.d sources.list.d.old
  fi

  LB_SRCTOP=$(pwd)/uberbau.bats.dir.tmp
  rm -rf "$LB_SRCTOP"
  mkdir -p "$LB_SRCTOP"
  cd "$LB_SRCTOP"

  # Test with uncommitted changes
  ln -s .. ob-repobot
  PATH=$(cd ..; pwd):$PATH
  uberbau --help
  #uberbau set-gspeak 3.28
  uberbau install_deps
  if test -d /Applications
  then
    # mac
    uberbau nuke
  else
    # on Ubuntu, have to mirror oblong-spruce now that depdemo depends on it... 'bau all --lclone' gets it by mirroring all of nobuild.
    uberbau nuke oblong-spruce
  fi
  uberbau clone depdemo-particle depdemo-proton
  uberbau build depdemo-particle depdemo-proton
  #uberbau -v mirror gspeak

  cd ..
  rm -rf "$LB_SRCTOP"

  if test -d sources.list.d.old
  then
    sudo mv /etc/apt/sources.list.d /etc/apt/sources.list.d.old.$$
    sudo mv sources.list.d.old /etc/apt/sources.list.d
    sudo apt-get update
  fi
}
