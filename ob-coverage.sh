#!/bin/sh
set -ex
# Run at beginning and end of ctest if COVERAGE enabled to output coverage test report.

# Run with current directory at the top of the source tree because
# that's where bau expects coverage-report to land

# Refer to absolute top source directory (just to be clear)
srctop="$(pwd)"

# FIXME: If we need .xml output to integrate with some tool, consider
# switching from lcov to gcovr

case "$1" in
start|begin)
  echo "ob-coverage.sh: Zeroing coverage counters"
  lcov --quiet --directory . --zerocounters
  ;;
stop|end)
  echo "ob-coverage.sh: Generating coverage report"

  lcov --quiet --directory . --no-external --capture -o coverage-raw.lcov
  # We don't want to include tests in the coverage output normally,
  # but it is sometimes interesting to see which tests are being
  # skipped.  We could output a separate report for that.
  #
  # Use absolute output path to work around bug fixed by
  # https://github.com/linux-test-project/lcov/commit/632c25a0d1f5e4d2f4fd5b28ce7c8b86d388c91f
  # FIXME: figure out where negative counts come from

  # Remove stats for gtest
  lcov --quiet --remove coverage-raw.lcov -o "$(pwd)/coverage.lcov" "$srctop/gtest*"

  # Remove stats for all directories named 'test' (that aren't in btmp, etc.)
  # Have to use a loop, can't just list them all on one line, because
  # patterns look like filesystem wildcards, and can't be escaped.
  # FIXME: probably breaks if current directory has a space in it
  for line in $(find "$srctop" \
     -name btmp -prune -o \
     -name 'obj-*' -prune -o \
     -name debian -prune -o \
     -name coverage-report -prune -o \
     -name tests -print)
  do
     lcov --quiet --remove coverage.lcov -o coverage-x.lcov "$line/*"
     mv coverage-x.lcov coverage.lcov
  done

  rm -rf coverage-report
  genhtml --quiet --output-directory coverage-report coverage.lcov

  echo "ob-coverage.sh done.  To view coverage report, open $(pwd)/coverage-report/index.html in a browser."
  ;;
*)
  echo "usage: $0 [start|stop]"
  exit 1
  ;;
esac
