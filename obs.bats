#!/usr/bin/env bats

@test "obs-smoke" {
  ./obs detect_ncores
  ./obs detect_os
  ./obs get_major_version_git
  ./obs get_version_git
  ./obs yovo2cefversion 4.0
  ./obs yovo2yoversion 4.0
  ! ./obs blart
  ./obs --help
  ! ./obs apt-key-gen
  rm -rf foo.tmp
  export BS_APT_LOCALBUILD=`pwd`/foo.tmp
  ./obs apt-key-gen
  ./obs apt_server_init xyzzy $BS_APT_LOCALBUILD/repo.pubkey
  ./obs apt_server_add localhost $BS_APT_LOCALBUILD/repo.pubkey $BS_APT_LOCALBUILD/repobot/xyzzy/apt
  ./obs apt_server_rm localhost $BS_APT_LOCALBUILD/repo.pubkey $BS_APT_LOCALBUILD/repobot/xyzzy/apt
  ./obs apt-key-rm
  rm -rf foo.tmp
}
