Oblong Bootstrap Script
=======================

`obs` is a tiny tool for mac and windows that can install local packages which don't belong in the app store or brew.

It does not support transitive dependencies -- it just finds the tarball and unpacks it.

(On Linux, use the system's package manager instead.)

## Getting Started

First, arrange for passwordless login to the package server, e.g.:

```
$ ssh-copy-id buildhost4.oblong.com
```

Then:

On Mac, [install brew if you don't already have it](https://brew.sh/), then do:

```
$ brew tap Oblong/tools
$ brew install obs
```

On Ubuntu, do:

```
$ sudo apt-get install oblong-obs
```

On Windows, in a Cygwin window, do:

```
$ git clone https://github.com/Oblong/obs.git
$ cd obs
$ make install
```

## Usage

### Installing packages

```
$ obs install yobuild11 g-speak3.31
```

### Listing available packages

```
$ obs list
```

You can search for particular packages by passing the output of 'obs list' to a tool like [grep](http://www.uccs.edu/~ahitchco/grep/).

## Troubleshooting

If obs acts funny, see if the latest version works better, e.g. on Mac, do

```
$ brew upgrade obs
```

If cmake explodes, it probably means you missed installing a package with obs.   You can guess what's needed by looking at debian/control and/or cmake errors, then figure out the name of the exact package to install with `obs list`.

If programs crash, you're probably mixing old and new packages.

To fix that for packages installed with obs, your best bet is to remove all packages and start over with the rather extreme:

```
$ sudo rm -rf /opt/oblong
```

(On Cygwin, it's ```rm -rf /cygdrive/c/opt/oblong```.)

## Using list and install together

For example, to install greenhouse and webthing, use 'obs list' to discover dependencies, then 'obs install' them:

```
$ obs list | grep yobuild
oblong-yobuild11-cef2704
oblong-yobuild11-cef3112
oblong-yobuild11-v8-4.2.77
oblong-yobuild11-v8-5.2.361
oblong-yobuild12-cef3112
yobuild11
yobuild12
$ obs install yobuild11 oblong-yobuild11-cef2704
$ obs list | egrep 'g-speak|webthing|greenhouse|staging' | grep 3.31
g-speak3.31
g-speak-gh3.31
oblong-greenhouse-gs3.31x
oblong-greenhouse-gs-gh3.31x
oblong-webthing-cef2704-gs3.31x
oblong-webthing-cef2704-gs-gh3.31x
staging3.31
staging-gh3.31
$ obs install g-speak3.31 oblong-greenhouse-gs3.31x oblong-webthing-cef2704-gs3.31x staging3.31
```

## Other functions and options

`obs --help` lists other things obs can do.  For instance:

To look up the version of yobuild that a given release of the oblong platform uses:

```
$ obs yovo2yoversion 3.20
10
```

To look up the version of cef that a given release of the oblong platform uses:

```
$ obs yovo2cefversion 3.20
cef2272
```

To install some other operating system's build of a package
(handy e.g. on osx1013 if all that's been built is for osx1012):

```
$ BS_FORCE_OS=osx1012 obs install yobuild11 g-speak3.28
```

To use a different username when accessing the package server:

```
$ bs_install_user=joe obs list
```

Alternately, add something like this to ~/.ssh/config:

```
Host buildhost4.oblong.com
  User joe
```

To access a different package server:

```
$ MASTER=server.example.com obs pkg_list
```

## ob-set-defaults

ob-set-defaults modifies a project's source tree slightly to set defaults
for e.g. which version of g-speak to install when building the project.

Individual projects can override this by putting their own version
in an executable sh script named set-gspeak.sh.

More simply, they can override some defaults by creating a file
ci/ob-set-defaults.conf containing variable settings like
```
PREFIX=/opt/oblong/my-funky-dir
opt_generator="Unix Makefiles"
```
Read the top of ob-set-defaults to see which variables can be set.

See ob-set-defaults --help for more info.
