#!/usr/bin/bats

@test compiler {
  # Oddly, bs_funcs.sh requires SRC to be set
  SRC=$(pwd)
  . ./bs_funcs.sh

  # Also oddly, bs_vcvars requires opt_toolchain to be set
  opt_toolchain=`bs_detect_toolchain`
  bs_vcvars 64

  # Make sure cl.exe can compile a program
  echo "int main() {return 0;}" > dummy.c
  cl dummy.c

  rm dummy.c dummy.obj dummy.exe
}
