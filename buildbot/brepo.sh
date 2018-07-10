#!/bin/sh
# Maintain build results trees, each containing a raw build artifact
# repository, an apt repository, and later, a yum repository and maybe
# directories for windows and mac installers.
#
# For apt:
# See http://wiki.debian.org/RepositoryFormat for terminology and layout
# Uses reprepro to maintain the apt repository.

set -e

. ../obs_funcs.sh

# Hardcoded configuration
# FIXME: make this configurable via a data file?
#
# General
# Following lines must match ones in local.sh and obs_funcs.sh
bs_upload_user=${bs_upload_user:-buildbot}
bs_repodir=${bs_repodir:-repobot}
bs_repotop=${bs_repotop:-/home/buildbot/var/$bs_repodir}
#
# Apt
cur_distro=$(awk -F= '/CODENAME/{print $2}' /etc/lsb-release)
bs_suites="${bs_suites:-${cur_distro}}"
set -x

usage() {
cat << _EOF_
Manage build results repository.

Usage:
  sh brepo.sh install
    Install reprepro and create $bs_repotop.  Run as root.

  sh brepo.sh init ARCHIVE_NAME
    Initialize a repo at $bs_repotop/ARCHIVE_NAME/apt.

  sh brepo.sh add ARCHIVE_NAME suite section file...
    Upload a .deb to the given repo for the given suite, and update its index.
    Uses locking so multiple runs at same time don't explode.
    ARCHIVE_NAME is the apt repo's name (e.g. 'dev' or 'rel')
    Suite is e.g. 'xenial'
    Section is the Debian section aka component (e.g. 'main' or 'non-free')

  sh brepo.sh remove ARCHIVE_NAME suite section packagename...
    Remove a package from the repository.
    e.g. sh brepo.sh remove rel-xenial xenial non-free oblong-gstreamer1.2

  sh brepo.sh uninit ARCHIVE_NAME
    Delete $bs_repotop/ARCHIVE_NAME/apt.

  sh brepo.sh uninstall.  Run as root.
    Remove the repo management tools.

Set env var bs_repotop to force a different top directory.
_EOF_
}

# Process initial argument
verb="$1"
case "$verb" in
-h|--help) usage; exit 0;;
"") usage; exit 1;;
esac
shift

set -x

do_install() {
    mkdir -p $bs_repotop
    reprepro --version || sudo apt-get install -y reprepro
    flock --version || sudo apt-get install -y flock
}

do_init() {
    #ARCHIVE_ROOT=$bs_repotop/$ARCHIVE_NAME
    #APT_ARCHIVE_ROOT=$ARCHIVE_ROOT/apt

    if test -d $APT_ARCHIVE_ROOT
    then
        bs_abort "$APT_ARCHIVE_ROOT already exists"
    fi

    bs_apt_server_init $ARCHIVE_NAME $bs_repotop/repo.pubkey $bs_suites
}

# Usage: do_add $kind-$apt_codename $apt_codename non-free *.deb
do_add() {
    # ARCHIVE_NAME was already parsed and that arg shifted off
    local suite=$1
    shift
    local section=$1
    shift
    # section is ignored, taken from package
    bs_apt_pkg_add $ARCHIVE_NAME $suite $@
}

# Usage: do_remove $kind-$apt_codename $apt_codename non-free pkgname...
do_remove() {
    # ARCHIVE_NAME was already parsed and that arg shifted off
    local suite=$1
    shift
    local section=$1
    shift
    # section is ignored, taken from package
    bs_apt_pkg_rm $ARCHIVE_NAME $suite $@
}

do_uninit() {
    rm -r $APT_ARCHIVE_ROOT
}

do_uninstall() {
    apt-get remove -y reprepro
    rm -rf $bs_repotop
}

case $verb in
install|uninstall) ;;
*)
    if ! test -d $bs_repotop
    then
        bs_abort "Directory $bs_repotop does not exist"
    fi
    if ! test -w $bs_repotop
    then
        bs_abort "Directory $bs_repotop is not writable by this user"
    fi
 
    ARCHIVE_NAME=$1
    case "$ARCHIVE_NAME" in
    "") bs_abort "Expected ARCHIVE_NAME as first argument";;
    esac

    # The intent is to have directories under $bs_repotop/$ARCHIVE_NAME
    # raw for bare tarballs, yum for a yum repo, apt for an apt repo, etc.
    ARCHIVE_ROOT=$bs_repotop/$ARCHIVE_NAME

    APT_ARCHIVE_ROOT=$ARCHIVE_ROOT/apt

    shift
    ;;
esac

case $verb in
install)
    do_install
    ;;
init)
    do_init
    ;;
add)
    do_add $@
    ;;
remove)
    do_remove $@
    ;;
uninit)
    do_uninit
    ;;
uninstall)
    do_uninstall
    ;;
*)
    usage
    bs_abort "unknown verb $verb"
    ;;
esac

echo "Done."
