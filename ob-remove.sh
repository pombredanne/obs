#!/bin/sh
set -e
set -x

echo "Script to uninstall everything oblong-related, along with their config files.  Caution: may remove more than you expect."

# set $opt_rubytoo to anything if you want to remove all ruby gems

# Set this to true if you want to remove dependencies (including ruby), too
opt_autoremove=${opt_autoremove:-false}

OLDPKGS=`dpkg-query -l | egrep -i 'g-speak|oblong|mezzanine|whiteboard|corkboard|ob-http-ctl|libpdl-opencv-perl|libpdl-linearalgebra-perl|libpdl-graphics-gnuplot-perl|ob-awesomium|build-deps' | awk '{print $2}' | egrep -v "oblong-obs"`
if test "$opt_rubytoo"
then
    OLDGEMS=`dpkg-query -l | egrep rubygem- | grep -v integration | awk '{print $2}' || true`
fi
if test "$OLDPKGS"
then
    OLDPKGS="$OLDPKGS $OLDGEMS"
else
    OLDPKGS="$OLDGEMS"
fi

if test "$OLDPKGS"
then
    dpkg -r $OLDPKGS || true
    apt-get remove -y $OLDPKGS || true
fi
pkgs="\
    'mezzanine*' \
    'whiteboard*' \
    'corkboard*' \
    'ob-http-ctl' \
    'g-speak3.*' \
    'g-speak-*' \
    'oblong-*' \
    'libopencv-*' \
    libpdl-opencv-perl \
    libsub-exporter-progressive-perl \
    ultrasonic-calibration-oblong"

apt-get remove -y $pkgs || true

if test "$OLDPKGS"
then
    dpkg --purge $OLDPKGS || true
fi

if $opt_autoremove
then
    apt-get autoremove -y || true
fi

# Sanity check: make sure nothing in /opt/oblong
if dpkg-query -S /opt/oblong
then
    echo fail, /opt/oblong not empty
    exit 1
fi

if ls /opt/oblong
then
    echo warning, removing non-packaged files from /opt/oblong
    rm -rf /opt/oblong
fi

checkfiles() {
    if ls "$@"
    then
        echo FIXME: $@ was not removed.  See https://bugs.oblong.com/show_bug.cgi?id=7687
        rm -rf "$@"
    fi
}
checkfiles /etc/init.d/mz
checkfiles /etc/init.d/mz-pools-setup
checkfiles /etc/init.d/ob-http-ctl
checkfiles /etc/init.d/x11
checkfiles /etc/logrotate.d/ob-rotate-mezzanine
checkfiles /etc/oblong/quartermaster
checkfiles /etc/oblong/startup-commons
checkfiles /etc/oblong/xinitrc

for dir in /var/ob /etc/oblong /mnt/poolsramdisk
do
    if lsof $dir
    then
        echo WARNING: processes still using $dir
        echo Please kill them, then re-run
        exit 1
    fi

    if ls $dir
    then
        echo warning, removing leftover files
        rm -rf $dir
    fi
done

if test "$opt_rubytoo"
then
    # Remove all gems, since having wrong versions of gems can cause problems for mezzanine
    if test -f /usr/bin/gem
    then
        case `ruby --version` in
        "ruby 1"*)
          gem list --no-versions |
            xargs --no-run-if-empty gem uninstall --executables --user-install --all
            ;;
        *)
          # ruby 2 added notion of default gems that cannot be uninstalled
          gem list --no-versions |
            grep -v -E "(bigdecimal|io-console|json|minitest|psych|rake|rdoc|test-unit)" |
            xargs --no-run-if-empty gem uninstall --executables --user-install --all --force
            ;;
        esac
    fi

    # Remove system gems next, since doing so may also uninstall gem iself
    SYSRUBYGEMS="`dpkg-query -S /usr/lib/ruby/vendor_ruby | sed 's/:.*//;s/,//g'`"
    if test "$SYSRUBYGEMS"
    then
        apt-get purge -y $SYSRUBYGEMS
    fi

    # Finally, totally uninstall all traces of ruby, since our packages should pull that in via dependencies as well.
    if $opt_autoremove
    then
        SYSRUBYPKGS="`dpkg-query -l | grep ruby | awk '{print $2}'`"
        if test "$SYSRUBYPKGS"
        then
            apt-get purge -y $SYSRUBYPKGS
        fi
    fi
fi

if ps augxw | grep oblong | grep -v grep
then
    echo "Some oblong processes may still be running.  You may need to kill them and/or reboot."
fi

# You may also need to remove and purge monit if we've screwed up its config file.
echo "Success, everything removed.  If not, please contact Oblong."
