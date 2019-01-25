#!/usr/bin/env bats
@test "debian-star" {
  ./ob-filter-licenses tests/licenses/debian-star.in > debian-star.tmp
  diff -u tests/licenses/debian-star.out debian-star.tmp
  rm debian-star.tmp
}

@test "footnotes" {
  ./ob-filter-licenses tests/licenses/footnotes.in > footnotes.tmp
  diff -u tests/licenses/footnotes.out footnotes.tmp
  rm footnotes.tmp
}

@test "autoconfy" {
  ./ob-filter-licenses tests/licenses/autoconfy.in > autoconfy.tmp
  diff -u tests/licenses/autoconfy.out autoconfy.tmp
  rm autoconfy.tmp
}