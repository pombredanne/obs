PREFIX = /usr

all: bau.1 bau obs

%.1: %.1.txt
	# don't fail if manpage can't be formatted, e.g. on windows
	a2x --doctype manpage --format manpage $*.1.txt || touch $*.1

#VERSION := $(shell obs get-version)
# Integer version
#VERSIONOID := $(shell echo $$(( $$(sh ./obs.in get-major-version-git) * 1000 + $$(sh ./obs.in get-minor-version-git) )) )
# Alas, until we script brew updates differently, must hardcode version here.
VERSIONOID := 1005

# gnu make double-colon means only applies if dependency exists
%:: %.in
	echo VERSIONOID is $(VERSIONOID)
	sed 's/@VERSIONOID@/$(VERSIONOID)/' < $< > $@
	chmod +x $@

check: check-bau check-obs

check-bau:
	#if test "`which bats`" != ""; then bats .; fi
	egrep -v '{|}' < bau.bats > bau-test.sh
	sh -xe bau-test.sh
	rm bau-test.sh

	egrep -v '{|}' < uberbau.bats > uberbau-test.sh
	sh -xe uberbau-test.sh
	rm uberbau-test.sh

check-obs:
	#if test "`which bats`" != ""; then bats .; fi
	egrep -v '@test|^}$$' < obs.bats > obs-test.sh
	sh -xe obs-test.sh
	rm obs-test.sh

install: install-bau install-obs

install-bau: bau.1
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 bau $(DESTDIR)$(PREFIX)/bin
	install -m 755 ob-coverage.sh $(DESTDIR)$(PREFIX)/bin
	install -m 755 uberbau $(DESTDIR)$(PREFIX)/bin
	install -m 755 -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 bau.1 $(DESTDIR)$(PREFIX)/share/man/man1/bau.1
	# fixme: should install bau-defaults to share, but that's awkward for now
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin/bau-defaults
	install -m 644 bau-defaults/buildshim-ubu $(DESTDIR)$(PREFIX)/bin/bau-defaults/buildshim-ubu
	install -m 644 bau-defaults/buildshim-osx $(DESTDIR)$(PREFIX)/bin/bau-defaults/buildshim-osx
	install -m 644 bau-defaults/buildshim-win $(DESTDIR)$(PREFIX)/bin/bau-defaults/buildshim-win
	install -m 644 bs_funcs.sh $(DESTDIR)$(PREFIX)/bin

install-obs:
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 644 obs_funcs.sh $(DESTDIR)$(PREFIX)/bin
	install -m 755 ob-set-defaults $(DESTDIR)$(PREFIX)/bin
	install -m 755 obs ob-remove.sh $(DESTDIR)$(PREFIX)/bin

uninstall: uninstall-bau uninstall-obs

uninstall-bau:
	rm -rf \
           $(DESTDIR)$(PREFIX)/bin/bau \
           $(DESTDIR)$(PREFIX)/bin/bau-defaults \
           $(DESTDIR)$(PREFIX)/bin/bs_funcs.sh \
           $(DESTDIR)$(PREFIX)/bin/ob-coverage.sh \
           $(DESTDIR)$(PREFIX)/bin/uberbau \
           $(DESTDIR)$(PREFIX)/share/man/man1/bau.1 \
           #

uninstall-obs:
	rm -rf \
           $(DESTDIR)$(PREFIX)/bin/ob-remove.sh \
           $(DESTDIR)$(PREFIX)/bin/obs \
           $(DESTDIR)$(PREFIX)/bin/ob-set-defaults \
           $(DESTDIR)$(PREFIX)/bin/obs_funcs.sh \
           #

clean:
	rm -rf *.tmp bau.1 obs bau
