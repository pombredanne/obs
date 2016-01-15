Oblong Bootstrap Scripts
========================

This is a tiny set of shell functions and tools which may be
useful in building, installing, or uninstalling oblong software.

## Install

### Mac

#### Homebrew
```bash
# Install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Get access to Oblong's tap
brew tap Oblong/tools

# Install
brew install obs

# Upgrading
brew update
brew upgrade obs
```

### Ubuntu
```bash
# Once you have access to oblong's repository or the Oblong g-speak SDK, just install the oblong-obs package, e.g.
sudo apt-get install oblong-obs
```

### Windows
#### Cygwin
```bash
git clone https://github.com/Oblong/obs.git
cd obs
sudo make install
```

## Examples

To uninstall all oblong packages (except oblong-obs):
```
$ ob-remove.sh

To look up the version of cef that a given release of the oblong platform uses:
```
$ obs yovo2yoversion 3.20
cef2272
```

### Package manipulation

obs understands a primitive notion of packages, i.e. tarballs to be unpacked, usually into /opt
This is mostly useful inside Oblong, and mostly on Mac and Windows (though occasionally also on Linux).
These packages are not yet transitive, so to install e.g. g-speak3.20 for scratch, you also need to specify
the yobuild10 package it depends on.

To list packages available for install:
```
$ obs pkg_list
```
(You will quickly discover you want to do 'ssh-copy-id $foo', where $foo is the package server, to avoid multiple prompts.)

To install g-speak 3.21 on a mac or windows (mostly only useful inside Oblong):
```
$ obs install yobuild10 g-speak3.21
```

To install some other operating system's build of a package
(handy e.g. on osx1010 if all that's been built is for osx109):
```
$ BS_FORCE_OS=osx109 obs install yobuild10 g-speak3.21
```

To use a different username when accessing the package server:
```
$ bs_install_user=joe obs pkg_list

To access a different package server:
```
$ MASTER=server.example.com obs pkg_list
```
