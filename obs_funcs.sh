# (C) 2014,2015,2015,2016 Oblong
# Shell functions used in oblong build scripts
# Shipped along with platform, so can be used in customer-facing samples
# NOTE: out of date versions of this package can be very confusing indeed to developers

# Print an error message and terminate with nonzero status.
bs_abort() {
    echo "fatal error: $*"
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
        printf %s "$BS_FORCE_OS"
        return
    fi
    # Detect OS
    case "$(uname -s)" in
    Linux)
        if grep -q "Ubuntu 10.04" /etc/issue ; then echo ubu1004
        elif grep -q "Ubuntu 12.04" /etc/issue ; then echo ubu1204
        elif grep -q "Ubuntu 14.04" /etc/issue ; then echo ubu1404
        elif grep -q "Ubuntu 16.04" /etc/issue ; then echo ubu1604
        elif grep -q "Ubuntu 17.04" /etc/issue ; then echo ubu1704
        elif grep -q "Ubuntu Core 16" /etc/issue ; then echo ubu1604
        elif grep -q "Ubuntu Artful Aardvark" /etc/issue ; then echo ubu1710
        else bs_abort "unrecognized linux" >&2
        fi
        ;;
    Darwin)
        macver=$(sw_vers -productVersion)
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

# Only used on Windows
bs_detect_toolchain()
{
    if test -d "/cygdrive/c/Program Files (x86)/Microsoft Visual Studio 14.0"
    then
        echo msvc2015
    elif test -d "/cygdrive/c/Program Files (x86)/Microsoft Visual Studio 12.0"
    then
        echo msvc2013
    elif test -d "/cygdrive/c/Program Files (x86)/Microsoft Visual Studio 10.0"
    then
        echo msvc2010
    else
        bs_abort "None of Visual Studio 2015, 2013, nor 2010 detected" >&2
    fi
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
    d1=$(git describe --long)
    # Strip off -CHECKSUM suffix, if any
    case $_os in
    osx*) xregx=-E;;
    *) xregx=-r;;
    esac
    d2=$(echo $d1 | sed $xregx 's/-g[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9]?[a-z0-9]?$//')
    # Strip off -COUNT suffix, if any
    d3=$(echo $d2 | sed 's/-[0-9]*$//')
    # Remove non-numeric prefix (e.g. rel- or debian/), if any
    d4=$(echo $d3 | sed 's/^[^0-9]*//')
    # Remove non-numeric suffix (e.g. -mz-gouda), if any
    d5=$(echo $d4 | sed 's/-[^0-9]*$//')
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
    # Handle whacky tarball qwt532.tar.gz whose paths start with ./
    dest="/$(tar -tf $1 | head -n2 | tail -n1)"
    case "$dest" in
    /usr/local/*) dest="/usr/local"; depth=2;;
    /opt/*) dest="/opt"; depth=1;;
    /./opt/*) dest="/opt"; depth=2;;
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

# If $1 isn't in file $2, append it
bs_append_to_file() {
   if ! grep -e "$1" "$2"
   then
      printf "# Appended by obs\n%s\n" "$1" >> "$2"
   fi
}

# Set up $GNUPGHOME for insecure but fast unattended key generation
bs_gnupg_init_insecure_unattended() {
    case "$GNUPGHOME" in
    $HOME|"") bs_abort "bs_gnupg_init_insecure_unattended: GNUPGHOME must be set to a short non-HOME path";;
    esac
    local gpgconf="$GNUPGHOME"/gpg.conf
    # Delete mercilessly now because rm -rf $bs_repotop doesn't delete $GNUPGHOME
    gpgconf --kill gpg-agent || true
    rm -rf "$GNUPGHOME"
    cp -a "$HOME"/.gnupg "$GNUPGHOME" || mkdir -m700 "$GNUPGHOME"
    bs_append_to_file no-tty "$gpgconf"
    bs_append_to_file batch  "$gpgconf"
    # Select quick but insecure RNG (for gpg2, select on commandline)
    #if gpg --quick-random --version >/dev/null 2>&1 ; then
    #    bs_append_to_file quick-random       "$gpgconf"
    #fi
}

# Generate a fake key; APT_CONFIG and GNUPGHOME are used to avoid
# contaminating real environment (somewhat)
bs_apt_key_gen() {
    if gpg -k | grep -C 1 Kwik-Expiring
    then
       bs_abort "Fake key already exists; do 'obs apt-key-rm' to remove."
    fi
    test "$APT_CONFIG" = "$bs_repotop/etc/apt.conf" || bs_abort "assertion failed"

    # If this is first call, configure private gpg and apt environments
    # (Generally, caller will do rm -rf $bs_repotop at start of the big build.)
    if ! test -f "$APT_CONFIG"
    then
       # Init apt environment
       mkdir -p "$bs_repotop/etc/sources.list.d"
       # Start off trusting everything we trusted before
       cp -a /etc/apt/trusted.gpg* "$bs_repotop/etc"
       cat > $APT_CONFIG <<_EOF_
Dir::Etc::sourceparts "$bs_repotop/etc/sources.list.d";
Dir::Etc::Trusted "$bs_repotop/etc/trusted.gpg";
Dir::Etc::TrustedParts "$bs_repotop/etc/trusted.gpg.d";
_EOF_
       # Init gpg environment
       bs_gnupg_init_insecure_unattended
    fi

    # Generate a repo key that lasts long enough for one build
    local days=30
    local realname="$(getent passwd $LOGNAME | cut -d: -f5 | cut -d, -f1)"
    local keyname="Kwik-Expiring Development-Only Key ($realname)"
    local keyemail="temp-repo@example.com"
    cat > gpg.in.tmp <<_EOF_
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: $keyname
Name-Email: $keyemail
Expire-Date: $days
_EOF_

    # We don't usually like installing these on the fly, but it makes bootstrapping easier.
    # Guess what?  On bare ubuntu 16.04, gpg2 is not installed until you install reprepro.
    # "make check" will fail without this here, even though reprepro itself isn't
    # used until later.
    # We could add a runtime dependency on reprepro in debian/control, but then
    # the bootstrap check in bs_funcs.sh would need to do apt-get install -f.
    if ! reprepro --version
    then
        sudo apt-get install -y reprepro
    fi

    if gpg --version | head -n 1 | grep ' 2\.'
    then
        # gpg 2 needs agent, and we don't want to use the desktop's
        gpg-agent --debug-quick-random --daemon -- \
        gpg --pinentry-mode loopback --passphrase '' --gen-key gpg.in.tmp
    else
        # Older gpg that does not need agent
        gpg --passphrase '' --gen-key --quick-random gpg.in.tmp < /dev/null

        # Extra step only needed for ubuntu 16.04 (which has both gpg and gpg2)
        if test -x /usr/bin/gpg2
        then
            gpg --passphrase '' --armor --export-secret-keys $keyemail \
            | gpg-agent --daemon -- \
              gpg2 --passphrase '' --import -
        fi
    fi
    rm gpg.in.tmp

    local keyfile
    keyfile=$bs_repotop/repo.pubkey
    gpg --armor --export $keyemail > $keyfile

    echo "Generated local repo's fake key $keyfile, contents:"
    gpg --with-fingerprint $keyfile
    echo "We only need it for one build, so it expires in $days days."
}

bs_apt_key_rm() {
    local keyfile
    keyfile=$bs_repotop/repo.pubkey

    if true
    then
        # guess what?  Easiest way to go to nuke it from orbit.
        bs_gnupg_init_insecure_unattended
    else
        # The gentle way.  Bit fragile though.
        local keyemail="temp-repo@example.com"
        local fingerprint
        fingerprint=$(gpg -k --with-colons $keyemail | awk -F: '/^fpr:/ {print $10}' | head -n 1)
        if gpg --version | head -n 1 | grep ' 2\.'
        then
            # gpg 2 needs agent, and we don't want to use the desktop's
            gpg-agent --daemon -- \
            gpg --pinentry-mode loopback --passphrase '' --yes --delete-secret-and-public-key "$fingerprint"
        else
            gpg --passphrase '' --delete-secret-and-public-key "$fingerprint"
            if test -x /usr/bin/gpg2
            then
                gpg-agent --daemon -- \
                gpg2 --pinentry-mode loopback --passphrase '' --yes --delete-secret-and-public-key "$fingerprint"
            fi
        fi
    fi

    rm -f $keyfile
}

# Make a signed apt server available to the apt command
# Usage:
#   bs_apt_server_add host key dir dir ...
# Use 'none' for no key.
# e.g.
#   bs_apt_server_add localhost dummy.key /var/apt/repo
#   bs_apt_server_add foo.com none /ubuntu
# To sneakly download a different OS's packages, set bs_apt_codename first (e.g. to xenial)
bs_apt_server_add() {
    local host=$1
    shift
    local key=$1
    shift
    # remaining args are read by for loop below

    local sources_list_d
    local maybesudo
    case $MASTER in
    localhost)
        maybesudo=""
        sources_list_d=${bs_repotop}/etc/sources.list.d
        ;;
    *)
        maybesudo=sudo
        sources_list_d=/etc/apt/sources.list.d
        ;;
    esac

    $maybesudo rm -f $sources_list_d/repobot-$host-*.list
    local _apt_codename
    _apt_codename=${bs_apt_codename:-"$(awk -F= '/CODENAME/{print $2}' /etc/lsb-release)"}
    local dpkgarch=$(dpkg --print-architecture)
    local dir
    local line
    local sdir
    for dir
    do
        sdir="$(echo $dir | tr '/' '-')"
        case "$host" in
        localhost)
            line="deb [arch=$dpkgarch] file:$dir $_apt_codename main non-free"
            ;;
        *)
            line="deb [arch=$dpkgarch] http://$host/$dir $_apt_codename main non-free"
            ;;
        esac
        echo "$line" | $maybesudo tee "$sources_list_d/repobot-$host-$sdir-$_apt_codename.list"
    done

    if test "$key" != "none"
    then
        sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-key add $key
    fi

    sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get update
}

# Undo bs_apt_server_add
# Usage:
# bs_apt_server_rm host
bs_apt_server_rm() {
    local host=$1
    shift
    local sources_list_d
    case $MASTER in
    localhost)
        sources_list_d=${bs_repotop}/etc/sources.list.d
        rm -f $sources_list_d/repobot-$host-*.list
        ;;
    *)
        sources_list_d=/etc/apt/sources.list.d
        sudo rm -f $sources_list_d/repobot-$host-*.list
        ;;
    esac
    sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get clean
    sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get update
}

# Create a package $1 with version $2 claiming to be in section $3
bs_apt_pkg_gen() {
    local name=$1
    local version=$2
    local section=$3

    rm -rf dummy.$$
    mkdir -p dummy.$$/debian/usr/local/bin
    cat > dummy.$$/debian/usr/local/bin/hello <<_EOF_
#!/bin/sh
echo 'hello, world!'
_EOF_
    chmod +x dummy.$$/debian/usr/local/bin/hello
    mkdir dummy.$$/debian/DEBIAN
    cat > dummy.$$/debian/DEBIAN/control <<_EOF_
Package: $name
Version: $version
Section: $section
Priority: optional
Architecture: all
Depends: base-files
Maintainer: Alfred E. Neuman <what@worry.me>
Description: Tiny package
 This package gives reprepro something to chew on.
_EOF_
    (cd dummy.$$
    dpkg-deb --build debian
    )
    mv dummy.$$/debian.deb ${name}_${version}_all.deb
    rm -rf dummy.$$
}

# Usage: bs_apt_server_init subdir pubkey [distro1 ...]
# Create an apt server rooted at $bs_repotop/subdir/apt  (FIXME: flip last two dirs someday)
# Pubkey can be either a short id or a pubkey file.
# Remaining arguments are which distros this repo should serve.
bs_apt_server_init() {
    local apt_subdir="$1"
    shift
    local apt_repokey="$1"
    shift
    local apt_suites="$*"

    if test "$apt_suites" = ""
    then
        apt_suites="$(awk -F= '/CODENAME/{print $2}' /etc/lsb-release)"
    fi

    if test -f "$apt_repokey"
    then
        # Extract first public key fingerprint from a public key file
        apt_repokey=$(gpg --with-colons "$apt_repokey" | awk -F: '/^pub:/ {print $5}' | head -n 1)
    fi

    local apt_archive_root="$bs_repotop/$apt_subdir/apt"
    if test -d "$apt_archive_root"
    then
        bs_abort "$apt_archive_root already exists"
    fi

    local apt_arches="i386 amd64 armhf source"
    local apt_sections="main non-free"

    local suite
    for suite in $apt_suites
    do
        mkdir -p "$apt_archive_root"/dists/$suite   # just so we can do sanity checks before uploading
    done
    local section
    for section in $apt_sections
    do
        mkdir -p "$apt_archive_root"/pool/$section
    done
    mkdir -p "$apt_archive_root"/conf
    > "$apt_archive_root"/conf/distributions
    for suite in $apt_suites
    do
        cat >> "$apt_archive_root"/conf/distributions <<_EOF_
Origin: obs
Label: obs
Codename: $suite
Architectures: $apt_arches
Components: $apt_sections
Description: hello my name is apt repository
SignWith: $apt_repokey

_EOF_
    done

    # We don't usually like installing these on the fly, but it makes bootstrapping easier
    if ! reprepro --version
    then
        sudo apt-get install -y reprepro
    fi
    # Now upload a dummy package to every section of every suite so "apt-get update" doesn't error out
    for section in $apt_sections
    do
        bs_apt_pkg_gen obs-hello-${section} 0.0.1 $section
        for suite in $apt_suites
        do
            if ! reprepro --ask-passphrase -S $section -Vb "$apt_archive_root" includedeb $suite obs-hello-${section}_0.0.1_*.deb
            then
               bs_abort "reprepro includedeb failed"
            fi
        done
        rm obs-hello-${section}_0.0.1_*.deb
    done
}

# Usage: bs_apt_pkg_add subdir suite pkg...
# Add given packages to distro $suite in the apt server rooted at $bs_repotop/subdir/apt
bs_apt_pkg_add() {
    local apt_subdir="$1"
    shift
    local apt_suite="$1"
    shift
    local apt_pkgs="$*"

    local apt_archive_root="$bs_repotop/$apt_subdir/apt"

    if ! test -d $apt_archive_root/dists
    then
        bs_abort "1st arg $apt_subdir looks wrong; no such directory $apt_archive_root/dists."
    fi
    if test -f $apt_suite
    then
        bs_abort "2nd arg should not be a .deb, it should be a suite name, like precise or quantal."
    fi
    if ! test -d $apt_archive_root/dists/$apt_suite
    then
        bs_abort "2nd arg (codename aka suite) $apt_suite does not exist in this apt repository."
    fi

    case "$apt_pkgs" in
    "") bs_abort "No packages were given to upload.";;
    esac

    for arg in $apt_pkgs
    do
        test -f $arg || bs_abort "Package $arg is not a file."
    done

    #set +x
    local pkgnames
    pkgarch=`echo $apt_pkgs | awk '{print $1}' | sed 's/.*_//;s/\.deb//'`
    for arg in $@
    do
        # remove first _ and everything after it, yielding the package name
        pkgname=${arg%%_*}
        pkgnames="$pkgnames $pkgname"
    done
    set -x

    # Acquire an exclusive lock on this repo
    # See how fd 9 is set up by redirection at end of this function
    local LOCKFILE=$apt_archive_root/reprepro.lock

    echo "Acquiring lock $LOCKFILE... time is `date`"
    (
    if ! flock 9
    then
        bs_abort "Could not aquire lock $LOCKFILE"
    fi
    echo "Acquired lock $LOCKFILE... time is `date`"

    # Whew.  All that sanity checking, and the payload is just one line.

    # Site-specific behavior ...
    case "$apt_subdir" in
    dev-*)
        # Remove the previous version of these packages to avoid dreaded
        # "Already existing files can only be included again, if they are the same, but..."
        # at least for dev builds, so people can force builds after an iz change.
        reprepro --architecture $pkgarch -Vb $apt_archive_root remove $apt_suite $pkgnames
        ;;
    esac

    # Note: Remove the --ask-passphrase once you've configured a key without one, or configured an agent, or something
    set +e
    LANG=C reprepro --ask-passphrase -P extra -Vb $apt_archive_root includedeb $apt_suite $@ > /tmp/reprepro.log.$$ 2>&1
    status=$?
    cat /tmp/reprepro.log.$$
    set -e
    if grep "Already existing files can only" /tmp/reprepro.log.$$
    then
        rm /tmp/reprepro.log.$$
        bs_abort "Repeat upload failed.  You can only upload a rel package once.  Maybe you meant to give this package a dev- tag?"
    fi
    rm /tmp/reprepro.log.$$
    echo $status > subshell.status.tmp
    if test $status -ne 0
    then
        bs_abort "Upload failed, see message above."
    fi

    ) 9>$LOCKFILE
    echo "Released lock $LOCKFILE... time is `date`"
    local status
    status=$(cat subshell.status.tmp)
    rm -rf subshell.status.tmp
    if test $status -ne 0
    then
        bs_abort "Upload failed, see message above."
    fi
}

# Usage: bs_apt_pkg_rm subdir suite pkg...
bs_apt_pkg_rm() {
    local apt_subdir="$1"
    shift
    local apt_suite="$1"
    shift
    local apt_pkgnames="$*"

    local apt_archive_root="$bs_repotop/$apt_subdir/apt"
    if ! test -d $apt_archive_root/dists
    then
        bs_abort "1st arg $apt_subdir looks wrong; no such directory $apt_archive_root/dists."
    fi
    if ! test -d $apt_archive_root/dists/$apt_suite
    then
        bs_abort "2nd arg (codename aka suite) $apt_suite does not exist in this apt repository."
    fi

    local LOCKFILE=$apt_archive_root/reprepro.lock

    echo "Acquiring lock $LOCKFILE... time is `date`"
    (
    reprepro -Vb $apt_archive_root remove $apt_suite $@
    ) 9>$LOCKFILE
    echo "Released lock $LOCKFILE... time is `date`"
}

# Provide a few variables by default
_os=$(bs_detect_os)

SUDO=sudo
case $_os in
cygwin) SUDO="" ;;
esac

# FIXME: provide fewer variables
# Most of these are from lazy old code

bs_repodir=${bs_repodir:-repobot}

# To do local builds, set MASTER to localhost, and bs_repotop to where to store
# artifacts, then do e.g. obs apt-key-gen; brepo.sh init
case "$MASTER" in
"") ;;
localhost)
    bs_upload_user=$LOGNAME
    # Change behavior of apt.  Careful, have to pass it through sudo!
    export APT_CONFIG="$bs_repotop/etc/apt.conf"
    # Change behavior of gpg.  Careful, have to pass it through sudo!
    # Alas, GNUPGHOME has to be a short absolute path,
    # as on Ubuntu 16.04, we don't have gpgconf --create-socketdir.
    # FIXME: this is likely to clash if run in parallel.
    if test "$BS_GNUPGHOME"
    then
        # Workaround to avoid clash during 'localbuild.sh build nobuild'
        echo "obs_funcs: Setting GNUPGHOME from BS_GNUPGHOME, only used by debian/rules as of this writing" >&2
        GNUPGHOME="$BS_GNUPGHOME"
    else
        GNUPGHOME=/tmp/obs_localbuild_gpghome_$LOGNAME.tmp
    fi
    export GNUPGHOME
    ;;
esac
bs_repotop=${bs_repotop:-/home/buildbot/var/$bs_repodir}
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
