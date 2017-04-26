PREFIX = /usr
COMMANDS = obs ob-remove.sh

all:
	echo No build needed.

check:
	if test "`which bats`" != ""; then bats .; fi

install:
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 644 obs_funcs.sh $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(COMMANDS) $(DESTDIR)$(PREFIX)/bin

