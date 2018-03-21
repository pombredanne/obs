#!/usr/bin/env bats

@test "obs-deps-filter" {
  echo "=== Begin test obs-deps-filter"
  # Get access to uncommitted obs and obs_funcs.sh
  PATH="$(pwd):$PATH"

  cd tests/deps

  for format in bare apt-get-install apt-get-install-s
  do
    obs -v deps-filter-log < $format.in > $format.tmp
    if ! diff -u $format.expected $format.tmp
    then
      echo "obs-deps-filter-log got wrong answer on format $format"
      exit 1
    fi
    rm $format.tmp
  done

  cd ../..

  echo "=== End test obs-deps-filter"
}

@test "obs-get-gspeak-version" {
  # Get access to uncommitted obs and obs_funcs.sh
  PATH="$(pwd):$PATH"

  rm -rf tests/mezzver/debian
  cd tests/mezzver
  cp -a debian-mezz588-gs399 debian
  # Test normally
  if test $(obs get_gspeak_version) != 3.99
  then
     echo "bs_get_gspeak_version failed the easy test"
     exit 1
  fi
  # Test when cd'd somewhere else
  sh -c '. obs_funcs.sh; \
   cd /tmp; \
   ver=$(bs_get_gspeak_version); \
   if test "$ver" != 3.99; \
   then \
     echo "bs_get_gspeak_version failed to remember pwd"; \
     exit 1; \
   fi \
  '
  cd ../..
  rm -rf tests/mezzver/debian
}

@test "obs-apt-pkg-get-transitive" {
  # Get access to uncommitted obs and obs_funcs.sh
  PATH="$(pwd):$PATH"

  case $(cat /etc/os-release) in
  *14.04*) gspeak=3.30;;
  *16.04*) gspeak=4.0;;
  *17.10*) gspeak=4.2;;
  esac
  yoversion=$(obs yovo2yoversion $gspeak)

  if test $(uname) = Linux
  then
    unset MASTER
    # Assumes we have access to the apt repo already.
    # Download a package and its dependencies
    # (but first uninstall them, and remove all cached previously installed
    # packages, or the trick doesn't work)
    sudo apt-get update
    sudo apt remove oblong-loam${gspeak} oblong-loam++${gspeak} || true
    sudo apt-get clean
    obs apt-pkg-get-transitive oblong-loam++${gspeak}

    # Verify they were downloaded
    for pkg in oblong-loam++${gspeak} oblong-loam${gspeak} oblong-yobuild${yoversion}-boost
    do
      if ! test -f ${pkg}*.deb
      then
	echo "FAIL: ${pkg}*.deb not found"
      fi
    done
    # Delete it, or it'll get uploaded!
    rm *.deb
  fi
}

@test "obs-artifact" {
  rm -rf obs-artifact.tmp
  mkdir obs-artifact.tmp
  cd obs-artifact.tmp
  # No info case
  want="default"
  got="$(../obs get-artifact-subdir)"
  if test "$got" != "$want"
  then
    echo "bs-artifact-subdir did not default correctly ($got != $want)"
    exit 1
  fi
  # Buildbot case
  want="foo/7"
  echo "$want" > ../bs-artifactsubdir
  got="$(../obs get-artifact-subdir; rm -f ../bs-artifactsubdir)"
  if test "$got" != "$want"
  then
    echo "bs-artifact-subdir did not sense buildbot metadata ($got != $want)"
    exit 1
  fi
  # gitlab-ci case
  want="bletch/42"
  got="$( (CI_PROJECT_PATH_SLUG=bletch CI_PIPELINE_ID=42 ../obs get-artifact-subdir) )"
  if test "$got" != "$want"
  then
    echo "bs-artifact-subdir did not sense gitlab-ci metadata ($got != $want)"
    exit 1
  fi
  cd ..
  rm -rf obs-artifact.tmp
}

@test "obs-upload-local" {
  # Verify that obs upload works in the local case
  # FIXME: rename option for forcing upload during try builds to BS_IS_TRY_BUILD_FORCE=false or something
  export BUILDSHIM_LOCAL_ALREADY_RUNNING=1
  export MASTER=localhost
  export bs_repotop=/tmp/obs-upload-test.dir
  echo "hello" > snort.dat
  tar -czf snort.tar.gz snort.dat
  ./obs upload obs-upload-test 1 0 0 snort.tar.gz
  mv snort.dat snort.dat.orig
  rm snort.tar.gz
  ./obs download obs-upload-test
  tar -xzvf snort.tar.gz
  if ! cmp snort.dat snort.dat.orig
  then
    echo "snort.dat not the same after round trip"
    exit 1
  fi
  rm -f snort.dat* snort.tar.gz
}

@test "obs-upload-remote" {
  # Verify that obs upload works in the remote case
  # FIXME: rename option for forcing upload during try builds to BS_IS_TRY_BUILD_FORCE=false or something
  export BUILDSHIM_LOCAL_ALREADY_RUNNING=1
  export MASTER=$(hostname)
  export bs_repotop=/tmp/obs-upload-test.dir
  echo "hello" > snort.dat
  tar -czf snort.tar.gz snort.dat
  ./obs upload obs-upload-test 1 0 0 snort.tar.gz
  mv snort.dat snort.dat.orig
  rm snort.tar.gz
  ./obs download obs-upload-test
  tar -xzvf snort.tar.gz
  if ! cmp snort.dat snort.dat.orig
  then
    echo "snort.dat not the same after round trip"
    exit 1
  fi
  rm -f snort.dat* snort.tar.gz
}

@test "obs-upload-local-artifacts" {
  # Verify that obs upload puts build artifacts where we expect.
  # Background:
  # ob-repobot maintains three parallel trees of build results:
  # 1) a 'tarballs' repository used by 'obs install', organized by version number, mostly used on mac and windows
  # 2) an 'apt' repository used by 'apt install', only used for .deb packages for linux
  # 3) a repository used by the 'artifacts' link on the web interface, organized by build number
  # obs-upload-local tested 1).  Now let's test 3).

  # bs_uploads2 saves the "3)" artifacts in $bs_repotop/$(bs_intuit_buildtype)/builds/$(bs_get_artifact_subdir),
  # so let's force that path by setting the build type and artifact subdirectory here:
  # To avoid interfering with real buildbot's bs-artifactsubdir file, do this test in a subdirectory!
  export BUILDSHIM_LOCAL_ALREADY_RUNNING=1    # needed for this test to work inside a try build
  export MASTER=localhost
  export bs_repotop=/tmp/obs-upload-test.dir
  export BS_FORCE_BUILDTYPE=rel
  expected_subdir=blort/1
  echo $expected_subdir > bs-artifactsubdir

  mkdir -p tmp.tmp
  cd tmp.tmp
    date > snortifact.dat
    tar -czf snortifact.tar.gz snortifact.dat
    ../obs upload obs-upload-test 1 0 0 snortifact.tar.gz
    if ! cmp snortifact.tar.gz $bs_repotop/$BS_FORCE_BUILDTYPE/builds/$expected_subdir/snortifact.tar.gz
    then
      echo "snortifact.tar.gz not uploaded where we expected it"
      exit 1
    fi
  cd ..

  rm -rf tmp.tmp bs-artifactsubdir
}

@test "obs-smoke" {
  # Smoke test the simple commands.
  ./obs | grep Usage
  ./obs detect_ncores
  ./obs detect_os
  ./obs get_major_version_git
  ./obs get_minor_version_git
  ./obs get_version_git
  ./obs get_changenum_git
  ./obs yovo2cefversion 4.0
  ./obs yovo2yoversion 4.0
  vers=$(./obs yovo2yoversion 4.0.5)
  if test "$vers" != 11
  then
    echo "obs yovo2yoversion 4.0.5 was $vers, wanted 11"
    exit 1
  fi
  ! ./obs blart
  ./obs --help
}
