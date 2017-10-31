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
    3.*|4.0)
        echo 11
        ;;
    4.*)
        echo 12
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
    4.0) echo cef2704;;
    4.*) echo cef3112;;
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
        10.13|10.13.*) echo osx1013;;
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
        echo "$NUMBER_OF_PROCESSORS"
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

# Look at source tree to see what version of cef this project builds against currently
# Returns same kinds of values as bs_yovo2cefversion
bs_get_cef_version() {
    egrep 'webthing-cef' debian/control 2>/dev/null | sed 's/.*webthing-cef/cef/;s/-.*//' | head -n1
}

# Look at source tree to see what version of g-speak this project builds against currently
bs_get_gspeak_version() {
    # Allow -gh suffix after g-speak or gs (it means "greenhouse free")
    # sed's regular expressions are a bit ugly
    #  egrep: (abc)?
    #  sed:   \(abc\)\{0,1\}
    if egrep -q 'g-speak(-gh)?[0-9]' debian/control
    then
        egrep 'g-speak(-gh)?[0-9]' debian/control | head -n 1 | sed 's/.*g-speak\(-gh\)\{0,1\}//;s/[^0-9.].*//'
    elif egrep -q 'gs(-gh)?[0-9.]+x' debian/control
    then
        egrep 'gs(-gh)?[0-9.]+x' debian/control | head -n 1 | sed 's/^.*gs\(-gh\)\{0,1\}\([1-9][0-9.]*\)x.*$/\2/'
    elif egrep -q 'oblong-plasma-ruby' debian/control
    then
        egrep 'oblong-plasma-ruby' debian/control | sed 's/.*ruby//;s/,.*//'
    elif grep -q g-speak bs-options.dat
    then
        # ob-set-defaults leaves this behind.  Useful for non-g-speak projects trickling down to g-speak projects.
        grep g-speak bs-options.dat | sed 's/.*--g-speak //;s/ .*//'
    elif egrep -q 'G_SPEAK_HOME=.*g-speak[0-9]' debian/rules
    then
        awk -F= '/G_SPEAK_HOME=/ {print $2}' debian/rules | sed 's/.*speak//'
    else
        bs_warn "bs_get_gspeak_version: cannot find g-speak version" >&2
    fi

    # If the above doesn't work reliably, we could also look in debian/rules for variables set by ob-set-defaults
}

# Get the package name (for use with bs_upload)
bs_get_pkgname() {
    awk 'BEGIN { status=1; }; /Source:/ {print $2; status=0;}; END {exit(status);}' < debian/control
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
    # git uses a variable number of digits in the hex hash ID
    d2=$(echo "$d1" | sed $xregx 's/-g[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9]*$//')
    # Strip off -COUNT suffix, if any
    d3=$(echo "$d2" | sed 's/-[0-9]*$//')
    # Remove non-numeric prefix (e.g. rel- or debian/), if any
    d4=$(echo "$d3" | sed 's/^[^0-9]*//')
    # Remove non-numeric suffix (e.g. -mz-gouda), if any
    d5=$(echo "$d4" | sed 's/-[^0-9]*$//')
    case "$d5" in
    "") bs_abort "can't parse version number from git describe --long's output $d1";;
    esac
    echo "$d5"
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
  "")
      bs_abort "bs_pkg_list: must specify bs_install_host"
      ;;
  localhost)
      (cd ${bs_install_root}; ls -d */$_os | sed 's,/.*,,')
      ;;
  *)
      ssh -o StrictHostKeyChecking=no -n "${bs_install_sshspec}" "cd ${bs_install_root}; ls -d */$_os | sed 's,/.*,,'"
      ;;
  esac
}

# return highest-versioned entry in given subdirectory of repo, if any
bs_pkg_latest_() {
  case "${bs_install_host}" in
  localhost)
      (cd "${bs_install_root}/$1" && ls | $sort --version-sort | tail -n 1)
      ;;
  *)
      ssh -o StrictHostKeyChecking=no -n "${bs_install_sshspec}" "cd '${bs_install_root}/$1' && ls | $sort --version-sort | tail -n 1"
      ;;
  esac
}

# Return absolute path to a sort that supports --version-sort on the master
bs_download_get_sort() {
    # Need newest sort for --version-sort.  On Mac, sort is too old and aborts, but gsort exists and is new enough.
    case "${bs_install_host}" in
    localhost)
        if sort --version-sort /dev/null 2>/dev/null
        then
            which sort
        elif gsort --version-sort /dev/null 2>/dev/null
        then
            which gsort
        else
            echo fail
        fi
        ;;
    *)
        # Same thing remotely; add brew's bin since ssh doesn't have it by default.
        ssh -o StrictHostKeyChecking=no -n "${bs_install_sshspec}" 'PATH="${PATH}":/usr/local/bin:/opt/local/bin; if sort --version-sort /dev/null 2>/dev/null; then which sort; elif gsort --version-sort /dev/null 2>/dev/null; then which gsort; else echo fail; fi'
    esac
}

# Usage: bs_download package ...
# Downloads the latest build of the given packages
bs_download() {
    bs_download_dest=${bs_download_dest:-.}
    case "${bs_install_host}" in
    "") bs_abort "bs_download: must specify bs_install_host";;
    esac

    sort=$(bs_download_get_sort)
    case $sort in
    /*) ;;
    *) bs_abort "A sort supporting --version-sort was not found.  Please install gnu sort (coreutils) on $bs_install_host."
    esac

    for depname
    do
        local xy=$(bs_pkg_latest_ $depname/$_os)

        # BEGIN KLUDGE: during transition to uploading as $(bs_get_pkgname), add in some special cases
        # Once all buildshims updated, remove kludge
        case "$depname" in
          oblong-*)    ;;
          *)
            if test "$xy" = ""
            then
              # Try prefixing dependency name with oblong- (hey, it works with staging...)
              local newname=oblong-$depname
              if xy=$(bs_pkg_latest_ $newname/$_os) && test "$xy" != ""
              then
                bs_warn "bs_download: name $depname deprecated, please use $newname"
                depname=$newname
              fi
            fi
            ;;
        esac
        # END KLUDGE

        case "$xy" in
        "") echo "bs_download: warning: package $depname not yet built for $_os"; return 1;;
        esac

        local micro=$(bs_pkg_latest_ "$depname/$_os/$xy")
        local patch=$(bs_pkg_latest_ "$depname/$_os/$xy/$micro")
        case "${bs_install_host}" in
        localhost)
             cp "${bs_install_root}/$depname/$_os/$xy/$micro/$patch"/*.tar.*z* "${bs_download_dest}";;
        *)
             scp -o StrictHostKeyChecking=no "${bs_install_sshspec}:${bs_install_root}/$depname/$_os/$xy/$micro/$patch/*.tar.*z*" "${bs_download_dest}/";;
        esac
    done
}

# Usage: bs_untar_restricted tarballname
# Simulates the command
#     $SUDO tar -C / -xf $tarball 2>&1
# but disallow installing into anywhere but /usr/local or /opt
# This avoids running afoul of Mac OS X 10.11 errors e.g. creating /usr
bs_untar_restricted() {
    local dest
    local depth
    # Detect destination.  Tarballs often start with the top level directories.
    # Choose the third entry, that should be /x/y/z/  (or /x/y/z/foo, depending on tar version)
    # Handle whacky tarball qwt532.tar.gz whose paths start with ./
    dest="/$(tar -tf $1 | head -n2 | tail -n1)"
    case "$dest" in
    /usr/local/*) dest="/usr/local"; depth=2;;
    /opt/*) dest="/opt"; depth=1;;
    /./opt/*) dest="/opt"; depth=2;;
    /cygdrive/c/opt/*) dest="/cygdrive/c/opt"; depth=3;;
    *) bs_abort "bs_untar_restricted: illegal destination $dest for tarball $1, only /usr/local and /opt allowed";;
    esac

    # Prepend c: if missing on windows
    if test "$_os" = cygwin && test "$dest" != "/cygdrive/c/opt"
    then
        dest="/cygdrive/c$dest"
    fi

    $SUDO mkdir -p "$dest"
    $SUDO tar -o --strip-components=$depth -C "$dest" -xf $1 2>&1
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
    for tarball in bs_install.tmp/*.tar.*z*
    do
        # FIXME: add a postinstall step to e.g. install things into /etc/oblong, like old yobuild had?
        bs_untar_restricted $tarball
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
    if ! reprepro --version > /dev/null 2>&1
    then
        sudo apt-get install -q -y reprepro
    fi

    if gpg --version | head -n 1 | grep ' 2\.' > /dev/null
    then
        # gpg 2 needs agent, and we don't want to use the desktop's
        gpg-agent --debug-quick-random --daemon -- \
        gpg -q --pinentry-mode loopback --passphrase '' --personal-digest-preferences SHA256 --gen-key gpg.in.tmp
    else
        # Older gpg that does not need agent
        gpg -q --passphrase '' --gen-key --quick-random gpg.in.tmp < /dev/null

        # Extra step only needed for ubuntu 16.04 (which has both gpg and gpg2)
        if test -x /usr/bin/gpg2
        then
            gpg -q --passphrase '' --armor --export-secret-keys $keyemail \
            | gpg-agent --daemon -- \
              gpg2 -q --passphrase '' --import -
        fi
    fi
    rm gpg.in.tmp

    local keyfile
    keyfile=$bs_repotop/repo.pubkey
    gpg --armor --export $keyemail > $keyfile

    #echo "Generated local repo's fake key $keyfile, contents:"
    #gpg --with-fingerprint $keyfile
    #echo "We only need it for one build, so it expires in $days days."
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
        if gpg --version | head -n 1 | grep ' 2\.' > /dev/null
        then
            # gpg 2 needs agent, and we don't want to use the desktop's
            gpg-agent --daemon -- \
            gpg -q --pinentry-mode loopback --passphrase '' --yes --delete-secret-and-public-key "$fingerprint"
        else
            gpg -q --passphrase '' --delete-secret-and-public-key "$fingerprint"
            if test -x /usr/bin/gpg2
            then
                gpg-agent --daemon -- \
                gpg2 -q --pinentry-mode loopback --passphrase '' --yes --delete-secret-and-public-key "$fingerprint"
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
    if test -f /etc/lsb-release
    then
        _apt_codename=${bs_apt_codename:-"$(awk -F= '/CODENAME/{print $2}' /etc/lsb-release)"}
    else
        _apt_codename=${bs_apt_codename:-"$(awk -F= '/VERSION_CODENAME/{print $2}' /etc/os-release)"}
    fi

    # FIXME: transition repos to SHA256 keys and remove this section
    # Ubuntu 1710 does not trust repos signed with SHA1 keys.
    # Until all repos we want to add have transitioned to SHA256 keys, be insecure there.
    # See https://wiki.ubuntu.com/SecurityTeam/GPGMigration
    local livedangerously
    case $_apt_codename in
    artful) livedangerously="trusted=true";;
    esac

    local dpkgarch=$(dpkg --print-architecture)
    local dir
    local line
    local sdir
    for dir
    do
        sdir="$(echo $dir | tr '/' '-')"
        case "$host" in
        localhost)
            line="deb [arch=$dpkgarch $livedangerously] file:$dir $_apt_codename main non-free"
            ;;
        *)
            line="deb [arch=$dpkgarch $livedangerously] http://$host/$dir $_apt_codename main non-free"
            ;;
        esac
        echo "$line" | $maybesudo tee "$sources_list_d/repobot-$host-$sdir-$_apt_codename.list" > /dev/null
    done

    if test "$key" != "none"
    then
        sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-key add $key
    fi

    sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get -q -q update
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
    sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get -q clean
    sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get -q update
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
    dpkg-deb --build debian > /dev/null
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
    if ! reprepro --version > /dev/null 2>&1
    then
        sudo apt-get install -q -y reprepro
    fi
    #gpg -k || true
    # Now upload a dummy package to every section of every suite so "apt-get update" doesn't error out
    for section in $apt_sections
    do
        bs_apt_pkg_gen obs-hello-${section} 0.0.1 $section
        for suite in $apt_suites
        do
            if ! reprepro --silent --ask-passphrase -S $section -Vb "$apt_archive_root" includedeb $suite obs-hello-${section}_0.0.1_*.deb > /tmp/reprepro.log.$$ 2>&1
            then
               cat /tmp/reprepro.log.$$
               bs_abort "reprepro includedeb failed"
            fi
            rm /tmp/reprepro.log.$$
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

    local pkgnames
    pkgarch=`echo $apt_pkgs | awk '{print $1}' | sed 's/.*_//;s/\.deb//'`
    for arg in $@
    do
        # remove first _ and everything after it, and first / and everything before it, yielding the package name
        pkgname=${arg%%_*}
        pkgname=${pkgname##*/}
        pkgnames="$pkgnames $pkgname"
    done

    # Acquire an exclusive lock on this repo
    # See how fd 9 is set up by redirection at end of this function
    local LOCKFILE=$apt_archive_root/reprepro.lock

    #echo "Acquiring lock $LOCKFILE... time is `date`"
    (
    if ! flock 9
    then
        bs_abort "Could not aquire lock $LOCKFILE"
    fi
    #echo "Acquired lock $LOCKFILE... time is `date`"

    # Whew.  All that sanity checking, and the payload is just one line.

    # Site-specific behavior ...
    case "$apt_subdir" in
    dev-*)
        # Remove the previous version of these packages to avoid dreaded
        # "Already existing files can only be included again, if they are the same, but..."
        # at least for dev builds, so people can force builds after an iz change.
        reprepro --silent --architecture $pkgarch -Vb $apt_archive_root remove $apt_suite $pkgnames > /dev/null
        ;;
    esac

    # Note: Remove the --ask-passphrase once you've configured a key without one, or configured an agent, or something
    #gpg -k || true
    set +e
    LANG=C reprepro --ask-passphrase -P extra -Vb $apt_archive_root includedeb $apt_suite $@ > /tmp/reprepro.log.$$ 2>&1
    status=$?
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
        cat /tmp/reprepro.log.$$
        bs_abort "Upload failed, see message above."
    fi

    ) 9>$LOCKFILE
    #echo "Released lock $LOCKFILE... time is `date`"
    local status
    status=$(cat subshell.status.tmp)
    rm -rf subshell.status.tmp
    if test "$status" != "0"
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

    #echo "Acquiring lock $LOCKFILE... time is `date`"
    (
    reprepro -Vb $apt_archive_root remove $apt_suite $@
    ) 9>$LOCKFILE
    #echo "Released lock $LOCKFILE... time is `date`"
}

# Download a set of packages and their dependencies into the current directory,
# filtering out any not from $MASTER.  This is a bit dirty.
# On entry:
#    you must already have access to the right repos on $MASTER
#    you must already have executed 'sudo apt clean'
bs_apt_pkg_get_transitive() {
    local filter
    case $MASTER in
    localhost) filter=file;;
    *)         filter=$MASTER;;
    esac

    # It is risky to parse verbose tool output, but I dunno where else to get the info.
    # Ubuntu 14.04: Get:1 http://buildhost4.oblong.com/repobot/rel-trusty/apt/ trusty/non-free oblong-loam3.30 amd64 3.30.12-0 [74.0 kB]
    # Ubuntu 16.04: Get:2 http://buildhost4.oblong.com/repobot/rel-xenial/apt/ xenial/non-free amd64 oblong-loam3.30 3.30.12-0 [74.0 kB]
    local field
    case $_os in
    ubu1404)
       field=4;;
    *) field=5;;
    esac

    local expanded
    for pkg in $(sudo GNUPGHOME="$GNUPGHOME" APT_CONFIG="$APT_CONFIG" apt-get install --download-only -y $* | awk '/^Get:[0-9].*:/ { print $'$field'}')
    do
        if apt-cache policy $pkg | grep -w -q ${filter}
        then
            expanded="$expanded $pkg"
        fi
    done

    apt-get -q download $expanded
}

#----------- begin upload support ---------------------------------------------------
# Not pretty.  Needs cleaning up.

# True if environment says this is a try build
bs_is_try_build() {
    case "$PWD" in
	*-trybuilder*) return 0;;  # true
	*) return 1;;  # false
    esac
}

# True if environment says not to publish the artifacts
bs_no_publish()
{
    if test "$BUILDSHIM_LOCAL_ALREADY_RUNNING" != ""
    then
        echo "Allowing upload even in a trybuilder, since it seems to be a nice safe uberbau build"
    else
        if bs_is_try_build
        then
            bs_warn "this is a try build, so not fully publishing artifacts"
            return 0
        fi
    fi
    if test "$BS_NO_PUBLISH"
    then
        bs_warn "BS_NO_PUBLISH set, so not fully publishing artifacts"
        return 0
    fi
    if test "$BS_NO_APT_UPLOAD"
    then
        bs_warn "BS_NO_APT_UPLOAD set, so not fully publishing artifacts.  (Deprecated; please set BS_NO_PUBLISH instead.)"
        return 0
    fi
    false
}

bs_create_empty_dir_on_master() {
    local dir=$1
    if echo "$dir" | egrep '^$|^/$|^/home/[a-z0-9]*$|^~[a-z0-9]*$|/$'
    then
        bs_abort "bs_create_empty_dir_on_master: directory $dir too dangerous to nuke" >&2
    fi
    if ! test "$BS_NO_CLEAN_UPLOAD"
    then
        local max_safe_size=3000000  # 3GB (qt 5.9 is 2.5GB on windows)
        case "$MASTER" in
        localhost)
            if test -d "$dir" && test "$(du -s "$dir" | cut -f1)" -gt $max_safe_size
            then
                bs_abort "directory $dir too big, aborting"
            else
                rm -rf "$dir"
            fi
            ;;
        *) ssh -o StrictHostKeyChecking=no -n "${bs_install_sshspec}" "if test -d '$dir' && test \$(du -s '$dir' | cut -f1) -gt $max_safe_size; then echo 'directory $dir too big, aborting'; exit 1; else rm -rf '$dir'; fi";;
        esac
    fi
    case "$MASTER" in
    localhost) mkdir -p "$dir";;
    *) ssh -o StrictHostKeyChecking=no -n "${bs_install_sshspec}" "mkdir -p '$dir'";;
    esac
}

# Output the name of the artifact directory
# Should be of the form $(bs_get_builder_name)/$buildnum
# If bs_artifactsubdir has been set (say, by bs_pkg_init), returns that.
# If on buildbot, reads magic file ob-repobot left in the parent directory.
# If on gitlab-ci, reads magic environment variable.
# Else returns the string "default" (an old convention).
bs_get_artifact_subdir() {
    if test "${bs_artifactsubdir}" != ""
    then
        echo "${bs_artifactsubdir}"
    elif test -f ../bs-artifactsubdir
    then
        # See ob-repobot/common/SimpleConfig.py
        cat ../bs-artifactsubdir
    elif test "$bs_origdir" && test -f "$bs_origdir/../bs-artifactsubdir"
    then
        # obs_funcs.sh sets bs_origdir when sourced
        # This matters on windows buildbots, which change to a short directory before building deeply nested things
        cat "$bs_origdir/../bs-artifactsubdir"
    elif test "$CI_PROJECT_PATH_SLUG" != ""
    then
        # See https://docs.gitlab.com/ee/ci/variables/
        # Requires gitlab >= 9.3
        echo "$CI_PROJECT_PATH_SLUG/$CI_PIPELINE_ID"
    else
        echo "default"
    fi
}

# If running on a buildbot, output its name and return true
# If not running on a buildbot, return false.  FIXME: return git repo name for local source build use case?
bs_get_builder_name() {
    case "$BS_FORCE_BUILDER_NAME" in
    "") ;;
    *) echo "$BS_FORCE_BUILDER_NAME"; return 0;;
    esac

    dir="$(pwd)"
    case "$dir" in
    *slave-state*) ;;
    *) return 1;;   # false
    esac

    # Strip '/build' suffix and remove dirname
    echo "$dir" | sed 's,/build/.*,,;s,/build$,,;s,.*/,,'
    return 0
}

# Retrieve source package name from debian directory
bs_get_package_name() {
    awk '/Source:/ {print $2};' < debian/control
}

# List the packages installed by the last run of bs_apt_install_deps
bs_apt_list_installed_deps() {
    awk '/^Unpacking/ {print $2}' < ../install_deps.log || true
}

bs_apt_uninstall_deps() {
    $SUDO apt-get -q autoremove --purge -y $(bs_apt_list_installed_deps) 'build-deps*' || true
    rm -f ../install_deps.log || true
}

bs_deps_clear() {
   # fixme: unify these
   # mac
   if test -f /opt/oblong/install_deps.log
   then
      $SUDO rm -f /opt/oblong/install_deps.log
   fi
   # linux
   if test -f ../install_deps.log
   then
      rm -f ../install_deps.log
   fi
}

# At build time, each builder will create two text files:
#  $platform / $buildername.in, containing the input files it downloads
#  $platform / $buildername.out, containing the output files it uploads
# These will later be used by common/SimpleConfig.py to set up dependencies

bs_deps_hook() {
    rm -rf bs_deps.tmp
    mkdir bs_deps.tmp
    if ! buildername=$(bs_get_builder_name)
    then
        echo "bs_deps_hook: not running on buildbot, so not saving dependency info"
        return 0
    fi
    echo "bs_deps_hook: builder $buildername reporting it uploads following artifacts: '$*'"

    case $_os in
    ubu*)
        # One file per line, remove directory and version number
        echo $* | tr ' ' '\012' | sed 's,.*/,,;s,_.*,,' > bs_deps.tmp/$buildername.out
        # Avoid circular dependencies caused by test install of output?
        bs_apt_list_installed_deps | fgrep -v  --line-regexp -f bs_deps.tmp/$buildername.out > bs_deps.tmp/$buildername.in || true
        ;;
    osx*)
        if test -f /opt/oblong/install_deps.log
        then
            cp /opt/oblong/install_deps.log bs_deps.tmp/$buildername.in
            bs_deps_clear
        fi
        # One file per line, remove directory and version number
        echo $* | tr ' ' '\012' | sed 's,.*/,,;s/-[0-9].*//;s/\.tar\..*z.*//' > bs_deps.tmp/$buildername.out
        ;;
    esac
    # Sanity check: make sure .in doesn't contain anything that was in .out
    # If output is empty, skip check (since otherwise it would match everything, whoops)
    ls -l bs_deps.tmp/$buildername.* || true
    if test "$*" != "" && fgrep --line-regexp -f bs_deps.tmp/$buildername.out bs_deps.tmp/$buildername.in
    then
        bs_abort "bs_deps_hook: bug: circular dependency"
    fi

    if ! echo bs_deps.tmp/* | fgrep '/*' > /dev/null
    then
        ls -l bs_deps.tmp

        deps_dest=$bs_repotop/bs_deps/$_os
        case ${MASTER} in
        localhost)
            mkdir -p $deps_dest
            cp bs_deps.tmp/* $deps_dest
            ;;
        *)
            ssh -o StrictHostKeyChecking=no -n "${bs_install_sshspec}" mkdir -p "$deps_dest"
            scp -o StrictHostKeyChecking=no bs_deps.tmp/* "${bs_install_sshspec}:$deps_dest/"
            ;;
        esac
    fi
    rm -rf bs_deps.tmp
}

bs_version_is_dev()
{
    # Odd Y means dev version
    if echo "$1" | egrep -q '^[0-9]+\.[0-9]*[13579]$|^[0-9]+\.[0-9]*[13579]\.[0-9]*$'
    then
        echo version $1 was dev >&2
        return 0
    else
        echo version $1 was rel >&2
        return 1
    fi
}

bs_get_project_buildtype_override() {
    # FIXME: project's buildshim should just set BS_FORCE_BUILDTYPE ?
    if bs_get_package_name | egrep -q 'oblong-admin-web|oblong-appup|mezz|mz'
    then
        bs_warn "Always using dev for mezz, even on rel branches." >&2
        echo dev
        return 0
    fi
    false
}

# Return which kind of repositories this build needs access to (dev or rel).
# Rule is:
#   If it's on a branch named rel*, and it depends on a rel version of g-speak, it should only have access to rel repos.
#   Otherwise it needs access to dev (and rel).
bs_intuit_buildtype_deps() {
    if test "$BS_FORCE_BUILDTYPE"
    then
        echo $BS_FORCE_BUILDTYPE
        return
    fi

    # Output project override, if any
    if bs_get_project_buildtype_override
    then
        return
    fi

    # If it is itself on a dev branch, it needs access to dev repos.
    case $(git describe) in
    rel*) ;;
    *)    echo "dev"; return;;
    esac

    # If it depends on a dev version of g-speak, it needs access to dev repos.
    if test "$gspeak" = ""
    then
        gspeak=$(bs_get_gspeak_version)
    fi
    if bs_version_is_dev "$gspeak"
    then
        echo "dev"; return
    fi

    echo "rel"
}

# Return which kind of repository to upload the result of this build to (dev or rel).
# If you're uploading a file, pass the name of the file being uploaded.
# Rule is:
#   If it was built with rel dependencies, is on a branch named rel*, and is tagged, it should be uploaded to a rel repo.
#   Otherwise it should be uploaded to a dev repo.
bs_intuit_buildtype() {
    if test "$BS_FORCE_BUILDTYPE"
    then
        echo $BS_FORCE_BUILDTYPE
        return
    fi

    case "$version_patchnum" in
    ""|0) ;;
    *)
        bs_warn "Not tagged, so marking this as a dev build." >&2
        echo "dev"; return;;
    esac

    # Otherwise upload to same kind of repo we get dependencies from.
    local ret=$(bs_intuit_buildtype_deps)

    # Sanity check -- if we're uploading files that refer to a dev
    # g-speak, make sure bs_intuit_buildtype_deps gave us access to dev repo.
    # FIXME: remove this, along with the argument?
    case $1 in
    *gs[0-9]*\.[0-9][13579]x*|*gs-gh[0-9]*\.[0-9][13579]x*)
        if test $ret != dev
        then
            bs_abort "BUG: bs_intuit_buildtype_deps should have already noticed you're using dev g-speak"
        fi
    esac

    echo $ret
}

# FIXME: old, awkward
# FIXME: this is the pair to bs_install
# FIXME: this should be part of bs_upload, or vice versa
bs_upload2()
{
    local project os abi micro changenumber

    project=$1;      shift
    os=$1;           shift
    abi=$1;          shift
    micro=$1;        shift
    changenumber=$1; shift

    case $os in
    osx*|cygwin|ubu*) ;;
    *) bs_abort "unrecognized os $os";;
    esac
    test $project || bs_abort "expected project"
    test $abi || bs_abort "expected abi"
    test $micro || bs_abort "expected micro"
    test -f $micro && bs_abort "micro should not be a file"
    test $changenumber || bs_abort "expected changenumber"
    test -f $changenumber && bs_abort "changenumber should not be a file"

    # Publish artifacts to the bs_install repo if appropriate
    if ! bs_no_publish
    then
        builds_dest=$bs_install_root/$project/$os/$abi/$micro/$changenumber
        bs_create_empty_dir_on_master $builds_dest
        case $MASTER in
        localhost)
          cp -a $* $builds_dest
          ;;
        *)
          scp -o StrictHostKeyChecking=no -p "$@" "${bs_install_sshspec}:$builds_dest/"
          ;;
        esac
        # Only fire the dependency hook if we actually publish (else try builders will sneak into the list of things to trigger)
        bs_deps_hook $*
    fi

    # Aaaand upload it again to the place buildbot's 'artifacts' link goes
    # bs_upload() has similar logic
    local artifactdir
    artifactdir="$(bs_get_artifact_subdir)"
    case "$artifactdir" in
    ""|"default")
        bs_warn "No build number from buildbot, so not archiving build artifacts"
        ;;
    *)
        kind=$(bs_intuit_buildtype $*)
        shasum $* | sed 's, .*/, ,' | tee sha1sums.txt
        builds_dest=$bs_repotop/$kind/builds/$artifactdir

        bs_create_empty_dir_on_master $builds_dest
        case $MASTER in
        localhost)
          cp -a $* sha1sums.txt $builds_dest
          ;;
        *)
          scp -o StrictHostKeyChecking=no -p "$@" sha1sums.txt "${bs_install_sshspec}:$builds_dest/"
          ;;
        esac
        ;;
    esac

    # Clear list of dependencies even if bs_no_publish, else next call to bs_deps_hook might get extra dependencies
    bs_deps_clear
}

#----------- end upload support ---------------------------------------------------

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
bs_origdir="$(pwd)"

# Allow user to download as a different user
bs_get_install_sshspec() {
    if test "$bs_install_user"
    then
        echo ${bs_install_user}@${bs_install_host}
    elif test "$LOGNAME" = SYSTEM
    then
        # Odd case: if running as service on cygwin, don't use name of system user.
        echo ${bs_upload_user}@${bs_install_host}
    else
        # Default: just use your own user id when sshing to MASTER
        echo ${bs_install_host}
    fi
}
bs_install_sshspec=$(bs_get_install_sshspec)

