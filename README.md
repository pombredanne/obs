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
# Once you have access to oblong's repository, just use apt-get
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

To install g-speak 3.21 on a mac or windows from a local buildbot (mostly only useful inside Oblong):
```
export MASTER=hostname-of-buildbot  (defaults to buildhost4)
$ obs install yobuild10 g-speak3.21
```
To install some other operating system's build of a package
(handy e.g. on osx1010 if all that's been built is for osx109):
```
$ BS_FORCE_OS=osx109 obs install yobuild10 g-speak3.21
```
