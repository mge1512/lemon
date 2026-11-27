# Makefile of lemongrass.
#
#   make             builds the program lemongrass
#   make check       runs the tests with that program
#   make install     installs the program and the templates
#   make uninstall   removes the installed files
#   make clean       removes the program and the directory build/
#
# Variables for the build:    CC, CPPFLAGS, CFLAGS, LDFLAGS
# Variables for the install:  PREFIX, BINDIR, DATADIR, DESTDIR, INSTALL
#
# Example for a package:
#   make CFLAGS="$RPM_OPT_FLAGS"
#   make check
#   make install PREFIX=/usr DESTDIR="$RPM_BUILD_ROOT"

CFLAGS  ?= -O2
PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
INSTALL ?= install

# The directory of the templates.
TEMPLATEDIR = $(DATADIR)/lemongrass
TEMPLATES   = tool/lempar.c tool/lempar.go tool/lempar.rs

.PHONY: all check install uninstall clean

all: lemongrass

lemongrass: tool/lemon.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ tool/lemon.c

# The test script builds the original generator with the same compiler.
check: lemongrass
	CC="$(CC)" LEMONGRASS=./lemongrass sh test/run.sh

install: lemongrass
	$(INSTALL) -d "$(DESTDIR)$(BINDIR)" "$(DESTDIR)$(TEMPLATEDIR)"
	$(INSTALL) -m 755 lemongrass "$(DESTDIR)$(BINDIR)/lemongrass"
	$(INSTALL) -m 644 $(TEMPLATES) "$(DESTDIR)$(TEMPLATEDIR)/"

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/lemongrass"
	rm -f "$(DESTDIR)$(TEMPLATEDIR)/lempar.c"
	rm -f "$(DESTDIR)$(TEMPLATEDIR)/lempar.go"
	rm -f "$(DESTDIR)$(TEMPLATEDIR)/lempar.rs"
	rmdir "$(DESTDIR)$(TEMPLATEDIR)" 2>/dev/null || true

clean:
	rm -f lemongrass
	rm -rf build
