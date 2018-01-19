#!/usr/bin/env bats
@test "obs-apt" {

 # Verify that we can download a standard package from the linux distro
 if test $(uname) = Linux
 then
  echo "=== Begin test obs-apt"
  #obs="./obs -v"
  obs="./obs"

  # Get access to uncommitted obs and obs_funcs.sh
  PATH="$(pwd):$PATH"

  # Generate a local repo key, create a local repo, get access to it
  export MASTER=localhost
  export bs_repotop=`pwd`/foo.tmp
  rm -rf $bs_repotop
  $obs apt-key-rm || true
  $obs apt-key-gen
  DISTRO=$(awk -F= '/CODENAME/{print $2}' /etc/lsb-release)
  echo DISTRO is $DISTRO
  $obs apt_server_init dev-or-rel $bs_repotop/repo.pubkey
  $obs apt_server_add localhost $bs_repotop/repo.pubkey $bs_repotop/dev-or-rel/apt

  # Verify that we cannot download our private package yet
  ! $obs $verbose run apt-get download obs-foobie

  # Generate and upload a private package
  $obs apt-pkg-gen obs-foobie 0.1 main
  echo DISTRO is still $DISTRO
  $obs apt-pkg-add dev-or-rel $DISTRO obs-foobie_0.1_all.deb
  rm obs-foobie_0.1_all.deb

  # Verify that we can see it in the repo and download it
  $obs sudo apt-get update
  $obs run apt-cache policy obs-foobie
  $obs run apt-get download obs-foobie
  test -f obs-foobie_0.1_all.deb
  rm obs-foobie_0.1_all.deb

  # Remove it from the repo, remove the repo from apt, remove the key, remove the repo.
  $obs apt-pkg-rm dev-or-rel $DISTRO obs-foobie
  $obs apt_server_rm localhost
  $obs apt-key-rm
  rm -rf foo.tmp
  unset bs_repotop
  echo "=== End test obs-apt"
 fi
}

