#!/usr/bin/env bats

@test "obs-smoke" {
  # Smoke test the simple commands.
  ./obs | grep Usage
  test "$(./obs --version)" = "obs versionoid 2"
  ./obs detect_ncores
  ./obs detect_os
  ./obs get_major_version_git
  ./obs get_version_git
  ./obs yovo2cefversion 4.0
  ./obs yovo2yoversion 4.0
  ! ./obs blart
  ./obs --help

  # Verify that we can download a standard package from the linux distro
  ./obs run apt-get download hello
  rm hello*.deb

  # Generate a local repo key, create a local repo, get access to it
  export MASTER=localhost
  export bs_repotop=`pwd`/foo.tmp
  rm -rf $bs_repotop
  ./obs apt-key-rm || true
  ./obs apt-key-gen
  DISTRO=$(awk -F= '/CODENAME/{print $2}' /etc/lsb-release)
  ./obs apt_server_init dev-or-rel $bs_repotop/repo.pubkey
  ./obs apt_server_add localhost $bs_repotop/repo.pubkey $bs_repotop/dev-or-rel/apt

  # Verify that we cannot download our private package yet
  ! ./obs run apt-get download obs-foobie

  # Generate and upload a private package
  ./obs apt-pkg-gen obs-foobie 0.1 main
  ./obs apt-pkg-add dev-or-rel $DISTRO obs-foobie_0.1_all.deb
  rm obs-foobie_0.1_all.deb

  # Verify that we can see it in the repo and download it
  ./obs sudo apt-get update
  ./obs run apt-cache policy obs-foobie
  ./obs run apt-get download obs-foobie
  test -f obs-foobie_0.1_all.deb
  rm obs-foobie_0.1_all.deb

  # Remove it from the repo, remove the repo from apt, remove the key, remove the repo.
  ./obs apt-pkg-rm dev-or-rel $DISTRO obs-foobie
  ./obs apt_server_rm localhost
  ./obs apt-key-rm
  rm -rf foo.tmp
  unset bs_repotop
}
