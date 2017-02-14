# (C) 2014,2015,2015,2016 Oblong
# Shell functions used in oblong build scripts
# Shipped along with platform, so can be used in customer-facing samples
# NOTE: out of date versions of this package can be very confusing indeed to developers

# Print an error message and terminate with nonzero status.
bs_abort() {
    echo fatal error: $*
    exit 1
}

# Print a warning message
bs_warn() {
    echo "warning: $*"
}

# Given a g-speak version number, output the major version of yobuild it uses.
bs_yovo2yoversion() {
    case $1 in
    2*|3.[0-9]|3.[0-9].*|3.1[01]*)
        # Errors to stderr since callers always redirect stdout to a variable
        bs_abort "unsupported yovo version $1" >&2
        ;;
    3.12*)
        echo 8
        ;;
    3.1[3456]*)
        echo 9
        ;;
    3.1[789]*|3.2[012]*)
        echo 10
        ;;
    3.*|4.*)
        echo 11
        ;;
    esac
}

# Given a g-speak version number, output the cef suffix common to the
# oblong-yobuildNN-cef and oblong-webthing packages it is usually bundled with.
# (You can pick a different CEF if you really want to, though.)
bs_yovo2cefversion() {
    case $1 in
    3.8|3.10|3.12|3.14|3.16|3.18) echo cef;;
    3.20) echo cef2272;;
    3.2[1-4]) echo cef2526;;
    3.2[5-9]|3.3[0-9])
        # bleah.  cef2704 does not build on ubu1204, yet we must still support 1204 for a bit.
        case $_os in
        ubu1204) echo cef2526;;
        *)       echo cef2704;;
        esac
        ;;
    4.*) echo cef2704;;
    *) bs_abort "bs_yovo2cefversion: don't know which CEF goes with g-speak $1" >&2;;
    esac
}

# Echo a short code for the operating system / version.
# e.g. osx107, osx109, ubu1004, ubu1204, ubu1404, or cygwin
# FIXME: should probably be win7 or win8 rather than cygwin

bs_detect_os() {
    if test "$BS_FORCE_OS"
    then
        echo $BS_FORCE_OS
        return
    fi
    # Detect OS
    case "`uname -s`" in
    Linux)
        if grep -q "Ubuntu 10.04" /etc/issue ; then echo ubu1004
        elif grep -q "Ubuntu 12.04" /etc/issue ; then echo ubu1204
        elif grep -q "Ubuntu 14.04" /etc/issue ; then echo ubu1404
        elif grep -q "Ubuntu 16.04" /etc/issue ; then echo ubu1604
        elif grep -q "Ubuntu Core 16" /etc/issue ; then echo ubu1604
        elif grep -q "Ubuntu Xenial Xerus" /etc/issue ; then echo ubu1604
        elif grep -q "Ubuntu Zesty Zaurus" /etc/issue ; then echo ubu1704
        else bs_abort "unrecognized linux" >&2
        fi
        ;;
    Darwin)
        macver=`sw_vers -productVersion`
        case "$macver" in
        # we pretend everything 10.7 or later is osx107 for now
        # Except that OS X 10.9 has a different Ruby ABI,
        # and we've decided to use XCode 4 on 10.7/10.8 vs.
        # XCode 5 on 10.9, so osx107 vs. osx109 here implies libstdc++ vs. libc++.
        10.12|10.12.*) echo osx1012;;
        10.11|10.11.*) echo osx1011;;
        10.10|10.10.*) echo osx1010;;
        10.9|10.9.*) echo osx109;;
        10.8|10.8.*) echo osx107;;
        10.7|10.7.*) echo osx107;;
        10.6|10.6.*) echo osx106;;
        *) bs_abort "unrecognized mac '$macver'" >&2 ;;
        esac
        ;;
    CYGWIN*WOW64) echo cygwin;;
    CYGWIN*)      echo cygwin;;
    *) bs_abort "unrecognized os" >&2 ;;
    esac
}

# Echo the number of CPU cores
bs_detect_ncores() {
    case $_os in
    ubu*)
        grep -c processor /proc/cpuinfo || echo 1
        ;;
    osx*)
        system_profiler -detailLevel full SPHardwareDataType | awk '/Total Number .f Cores/ {print $5};'
        ;;
    cygwin)
        echo $NUMBER_OF_PROCESSORS
        ;;
    esac
}

# Echo the version number of this project as given by git
# Assumes tags are like rel-3.x or dev-4.5.1, or maybe just 3.x, and returns the first numeric part including dots
# Ignores lightweight tags, i.e. assumes versions are tagged with git -a -m
bs_get_version_git() {
    # FIXME: this is overly complex
    # git describe --long's output looks like
    # tag-COUNT-CHECKSUM
    # or, if at a tag,
    # tag
    d1=`git describe --long`
    # Strip off -CHECKSUM suffix, if any
    case $_os in
    osx*) xregx=-E;;
    *) xregx=-r;;
    esac
    d2=`echo $d1 | sed $xregx 's/-g[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9]?[a-z0-9]?$//'`
    # Strip off -COUNT suffix, if any
    d3=`echo $d2 | sed 's/-[0-9]*$//'`
    # Remove non-numeric prefix (e.g. rel- or debian/), if any
    d4=`echo $d3 | sed 's/^[^0-9]*//'`
    # Remove non-numeric suffix (e.g. -mz-gouda), if any
    d5=`echo $d4 | sed 's/-[^0-9]*$//'`
    case "$d5" in
    "") bs_abort "can't parse version number from git describe --long's output $d1";;
    esac
    echo $d5
}

# Echo the major version number of this project as given by git
# Assumes tags are like rel-3.x or dev-4.5.1, or maybe just 3.x, and returns the first numeric part before a dot
# Ignores lightweight tags, i.e. assumes versions are tagged with git -a -m
bs_get_major_version_git() {
    # Remove anything after a dot, then remove anything before a dash
    git describe --long | sed 's/\..*//;s/.*-//'
}

# List packages that could be installed by bs_install
bs_pkg_list() {
  case "${bs_install_host}" in
  "") bs_abort "bs_pkg_list: must specify bs_install_host";;
  esac
  ssh -n ${bs_install_sshspec} "cd ${bs_install_root}; ls -d */$_os | sed 's,/.*,,'"
}

# Usage: bs_download package ...
# Downloads the latest build of the given packages
# This is not quite ready for external use
bs_download() {
    bs_download_dest=${bs_download_dest:-.}
    case "${bs_install_host}" in
    "") bs_abort "bs_download: must specify bs_install_host";;
    esac
    for depname
    do
        status=`ssh -n ${bs_install_sshspec} "if test -d ${bs_install_root}/$depname/$_os; then echo present ; else echo absent; fi"`
        case "$status" in
        present) ;;
        *) echo "bs_download: warning: package $depname not yet built for $_os"; return 1;;
        esac

        sort=`ssh -n ${bs_install_sshspec} 'PATH="${PATH}":/usr/local/bin:/opt/local/bin; if sort --version-sort /dev/null 2>/dev/null; then which sort; elif gsort --version-sort /dev/null 2>/dev/null; then which gsort; else echo fail; fi'`
        case $sort in
        /*) ;;
        *) bs_abort "A sort supporting --version-sort was not found.  Please install gnu sort (coreutils) on $bs_install_host."
        esac

        # Need newest sort for --version-sort.  On Mac, sort is too old and aborts, but gsort exists and is new enough.  gsort does not exist on linux.
        xy=`ssh -n ${bs_install_sshspec} "cd ${bs_install_root}/$depname/$_os; ls | $sort --version-sort | tail -n 1"`
        micro=`ssh -n ${bs_install_sshspec} "cd ${bs_install_root}/$depname/$_os/$xy; ls | sort -n | tail -n 1"`
        patch=`ssh -n ${bs_install_sshspec} "cd ${bs_install_root}/$depname/$_os/$xy/$micro; ls | sort -n | tail -n 1"`
        scp ${bs_install_sshspec}:${bs_install_root}/$depname/$_os/$xy/$micro/$patch/*.tar.gz ${bs_download_dest}
    done
}

# Usage: bs_untar_restricted tarballname
# Simulates the command
#     $SUDO tar -C / -xzf $tarball 2>&1
# but disallow installing into anywhere but /usr/local or /opt
# This avoids running afoul of Mac OS X 10.11 errors e.g. creating /usr
bs_untar_restricted() {
    local dest
    local depth
    # Detect destination.  Tarballs always start with the top level directories.
    # Choose the second entry, that should be /x/y/  (or /x/y/foo, depending on tar version)
    dest="/`tar -tf $1 | head -n2 | tail -n1`"
    case "$dest" in
    /usr/local/*) dest="/usr/local"; depth=2;;
    /opt/*) dest="/opt"; depth=1;;
    *) bs_abort "bs_untar_restricted: illegal destination $dest for tarball $1, only /usr/local and /opt allowed";;
    esac
    $SUDO mkdir -p "$dest"
    $SUDO tar -o --strip-components=$depth -C "$dest" -xzf $1 2>&1
}

# Usage: bs_install package ...
# Downloads and unpacks the latest build of the given packages
bs_install() {
    bs_download_dest=bs_install.tmp
    rm -rf ${bs_download_dest}
    mkdir ${bs_download_dest}
    bs_download $@

    # Remember what's been installed; will be used in bs_deps_hook
    # Keep it in /opt/oblong because that's the only place that's cleared at start of install_deps
    # FIXME: /opt/oblong doesn't always exist; caused trouble on win & linux
    if test -d /opt/oblong
    then
        echo $@ | tr ' ' '\012' | $SUDO tee -a /opt/oblong/install_deps.log
    fi

    # And now the scary part.  First, check for file (not directory) overwrites.
    for tarball in bs_install.tmp/*.tar.gz
    do
        case "$_os" in
        cygwin)
            # fixme: simplify, unify, allow other drives?
            # FIXME: this is crazy/fragile/broken, fix yobuild to not need this broken special case
            case $depname in
            yobuild*) root=/;;           # yobuild has /cygdrive/c in tgz!
            *)        root=/cygdrive/c;;
            esac
            tar -C $root -xzf $tarball 2>&1
            ;;
        *)  # osx1011 unhappy about setting ownership of /, understandably
            # FIXME: add a postinstall step to e.g. install things into /etc/oblong (kipple)?
            bs_untar_restricted $tarball
            ;;
        esac
    done

    rm -rf bs_install.tmp
}


# Provide a few variables by default
_os=`bs_detect_os`

SUDO=sudo
case $_os in
cygwin) SUDO= ;;
esac

# Defaults useful mostly inside Oblong.  Messy.  Only needed by bs_install et al.
# FIXME: refactor bs_upload / bs_install and clean this up
bs_repotop=${bs_repotop:-/home/buildbot/var/repobot}
MASTER=${MASTER:-buildhost4.oblong.com}
bs_upload_user=${bs_upload_user:-buildbot}
bs_install_host=$MASTER
bs_install_root=$bs_repotop/tarballs

# Allow user to download as a different user
if test "$bs_install_user"
then
    bs_install_sshspec=${bs_install_user}@${bs_install_host}
elif test "$LOGNAME" = SYSTEM
then
    # Odd case: if running as service on cygwin, don't use name of system user.
    bs_install_sshspec=${bs_upload_user}@${bs_install_host}
else
    # Default: just use your own user id when sshing to MASTER
    bs_install_sshspec=${bs_install_host}
fi
