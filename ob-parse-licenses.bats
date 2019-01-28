@test "libfontconfig1" {
  # Need . to run uninstalled ob-parse-licenses
  # Need $HOME/.local/bin to access scancode installed by ci/do-install-deps*
  PATH=.:$PATH:$HOME/.local/bin
  ob-parse-licenses tests/parse-licenses/libfontconfig1.in > libfontconfig1.tmp
  diff -u tests/parse-licenses/libfontconfig1.out libfontconfig1.tmp
  rm libfontconfig1.tmp
}

