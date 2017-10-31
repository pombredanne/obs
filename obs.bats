#!/usr/bin/env bats

@test "obs-apt-pkg-get-transitive" {
  # Get access to uncommitted ob-set-default and obs_funcs.sh
  PATH="$(pwd):$PATH"

  case $(cat /etc/os-release) in
  *14.04*) gspeak=3.30;;
  *16.04*) gspeak=4.0;;
  *17.10*) gspeak=4.1;;
  esac
  yoversion=$(obs yovo2yoversion $gspeak)

  if test $(uname) = Linux
  then
    unset MASTER
    # Assumes we have access to the apt repo already.
    # Download a package and its dependencies
    # (but first uninstall them, and remove all cached previously installed
    # packages, or the trick doesn't work)
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

# FIXME: make the ob-set-defaults test data-driven and shorter
@test "mezzver" {
  # Verify that setting g-speak version does not set mezzanine version

  # Get access to uncommitted ob-set-default and obs_funcs.sh
  PATH="$(pwd):$PATH"

  # Kludge: pass on raspberry pi
  BITS=$(getconf LONG_BIT)
  sed -i "s/deps-64-/deps-${BITS}-/" tests/*/*/rules

  cd tests

  cd mezzver

  rm -rf debian
  cp -a debian-mezz322-gs330 debian
  ob-set-defaults --g-speak 3.30
  if ! diff -ur debian-mezz322-gs330 debian
  then
    echo "ob-set-defaults --g-speak 3.30 did not give expected result on mezzanine"
    exit 1
  fi
  ob-set-defaults --mezz 3.22
  if ! diff -ur debian-mezz322-gs330 debian
  then
    echo "ob-set-defaults --mezz 3.22 did not give expected result on mezzanine"
    exit 1
  fi

  # FIXME: following tests are ugly because they use a future version
  # of cef, so must explicitly specify cef.
  rm -rf debian
  cp -a debian-mezz322-gs330 debian
  ob-set-defaults --g-speak 3.99 --mezz 5.88 --cef 3112
  if ! diff -ur debian-mezz588-gs399 debian
  then
    echo "ob-set-defaults --g-speak 3.99 --mezz 5.88 --cef 3112 did not give expected result on mezzanine"
    exit 1
  fi

  rm -rf debian
  cp -a debian-mezz322-gs330 debian
  ob-set-defaults --mezz 5.88 --g-speak 3.99 --cef 3112
  if ! diff -ur debian-mezz588-gs399 debian
  then
    echo "ob-set-defaults --mezz 5.88 --g-speak 3.99 --cef 3112 did not give expected result on mezzanine"
    exit 1
  fi

  rm -rf debian
  cp -a debian-mezz322-gs330 debian
  ob-set-defaults --g-speak 3.99 --cef 3112
  ob-set-defaults --mezz 5.88
  if ! diff -ur debian-mezz588-gs399 debian
  then
    echo "ob-set-defaults --g-speak 3.99 --cef 3112; ob-set-defaults --mezz 5.88 did not give expected result on mezzanine"
    exit 1
  fi

  rm -rf debian
  cp -a debian-mezz322-gs330 debian
  ob-set-defaults --mezz 5.88
  ob-set-defaults --g-speak 3.99 --cef 3112
  if ! diff -ur debian-mezz588-gs399 debian
  then
    echo "ob-set-defaults --mezz 5.88; ob-set-defaults --g-speak 3.99 did not give expected result on mezzanine"
    exit 1
  fi

  rm -rf debian
  cd ..

  cd adminweb

  rm -rf debian
  cp -a adminweb-mezz322-gs330 debian
  ob-set-defaults --g-speak 3.30
  if ! diff -ur adminweb-mezz322-gs330 debian
  then
    echo "ob-set-defaults --g-speak 3.30 did not give expected result on admin-web"
    exit 1
  fi
  ob-set-defaults --mezz 3.22
  if ! diff -ur adminweb-mezz322-gs330 debian
  then
    echo "ob-set-defaults --mezz 3.22 did not give expected result on admin-web"
    exit 1
  fi

  rm -rf debian
  cp -a adminweb-mezz322-gs330 debian
  ob-set-defaults --g-speak 4.0 --mezz 5.88
  if ! diff -ur adminweb-mezz588-gs40 debian
  then
    echo "ob-set-defaults --g-speak 4.0 --mezz 5.88 did not give expected result on admin-web"
    exit 1
  fi

  rm -rf debian
  cd ..

  cd ..
}

@test "greenhousever" {
  # Verify ob-set-defaults --greenhouse

  # Get access to uncommitted ob-set-default and obs_funcs.sh
  PATH="$(pwd):$PATH"

  cd tests

  cd greenhousever

  rm -rf debian
  cp -a greenhouse-gs41 debian
  ob-set-defaults --g-speak 4.1
  if ! diff -ur greenhouse-gs41 debian
  then
    echo "ob-set-defaults --g-speak 4.1 did not give expected result on greenhouse"
    exit 1
  fi

  rm -rf debian
  cp -a greenhouse-gs41 debian
  ob-set-defaults --g-speak 4.1 --greenhouse
  if ! diff -ur greenhouse-gs41-gh debian
  then
    echo "ob-set-defaults --g-speak 4.1 --greenhouse did not give expected result on greenhouse"
    exit 1
  fi

  rm -rf debian
  cd ..

  cd disasterver

  rm -rf debian
  cp -a disasterver-gs328 debian
  # have to use --major because test is not tagged same as original repo
  ob-set-defaults --g-speak 4.1 --major 1
  if ! diff -ur disasterver-gs41 debian
  then
    echo "ob-set-defaults --g-speak 4.1 did not give expected result on disaster"
    exit 1
  fi

  rm -rf debian
  cd ..
  cd ..
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
  ./obs get_version_git
  ./obs get_changenum_git
  ./obs yovo2cefversion 4.0
  ./obs yovo2yoversion 4.0
  ! ./obs blart
  ./obs --help
}

@test "obs-apt" {
 # Verify that we can download a standard package from the linux distro
 if test $(uname) = Linux
 then
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
 fi
}
