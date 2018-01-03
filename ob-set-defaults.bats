#!/usr/bin/env bats
set -ex

# FIXME: make this data-driven and shorter

@test "no-yobuild" {
  echo "no-yobuild: verify ob-set-defaults on non-yobuild projects"

  # Get access to uncommitted ob-set-default and obs_funcs.sh
  PATH="$(pwd):$PATH"

  # Create fake ob-version to foil yobuild fallback detection
  rm -f ob-version
  ln -s $(which false) ob-version
  if ob-version
  then
    echo "no-g-speak: fake ob-version did not take"
    exit 1
  fi

  cd tests

  cd mezzver

  rm -rf debian
  cp -a debian-plymouth-mz3.27 debian
  ob-set-defaults --mezz 3.28
  if ! diff -ur debian-plymouth-mz3.28 debian
  then
    echo "ob-set-defaults --mezz 3.28 did not give expected result on debian-plymouth"
    exit 1
  fi

  rm -rf debian
  cd ..

  cd ..
  rm -f ob-version
}

@test "no-g-speak" {
  echo "no-g-speak: verify ob-set-defaults on non-g-speak projects"

  # Get access to uncommitted ob-set-default and obs_funcs.sh
  PATH="$(pwd):$PATH"

  # Create fake ob-version to foil yobuild fallback detection
  rm -f ob-version
  ln -s $(which false) ob-version
  if ob-version
  then
    echo "no-g-speak: fake ob-version did not take"
    exit 1
  fi

  cd tests

  cd oblong-cef-ver

  rm -rf debian
  cp -a yb12-cef3239 debian
  ob-set-defaults -v --g-speak 4.4 --cef 3239
  if ! diff -ur yb12-cef3239 debian
  then
    echo "ob-set-defaults --g-speak 4.4 --cef 3239 did not give expected results on oblong-cef"
    exit 1
  fi

  rm -rf debian
  cp -a yb12-cef3282 debian
  ob-set-defaults -v --g-speak 4.4 --cef 3282
  if ! diff -ur yb12-cef3282 debian
  then
    echo "ob-set-defaults --g-speak 4.4 --cef 3282 did not give expected results on oblong-cef"
    exit 1
  fi

  rm -rf debian
  cd ..

  cd ..
  rm -f ob-version
}

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
  cp -a debian-plymouth-mz3.27 debian
  ob-set-defaults --g-speak 4.0 --mezz 3.28
  if ! diff -ur debian-plymouth-mz3.28 debian
  then
    echo "ob-set-defaults --g-speak 4.0 --mezz 3.28 did not give expected result on debian-plymouth"
    exit 1
  fi

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

