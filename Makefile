ifndef PREFIX
	PREFIX=/usr
endif

VERSION:=$(shell if [ -d .git ]; then bash -c '$(PREFIX)/bin/gitversion.sh | grep "^MAJOR=" | cut -d = -f 2'; else source version.sh && echo $$MAJOR ; fi)
RELEASE:=$(shell if [ -d .git ]; then bash -c '$(PREFIX)/bin/gitversion.sh | grep "^BUILD=" | cut -d = -f 2'; else source version.sh && echo $$BUILD ; fi)
DISTFILE=./dist/cmdarg-$(VERSION)-$(RELEASE).tar.gz

ifndef PREFIX
	PREFIX=''
endif

DISTFILE_DEPS=$(shell find . -type f | grep -Ev '\.git|\./dist/|$(DISTFILE)')
JUNIT_DEPS=$(wildcard *.sh) $(wildcard tests/*.sh)

all: $(DISTFILE)

# --- PHONY targets

.PHONY: clean srpm rpm gitclean dist test test-ci
clean:
	rm -f $(DISTFILE)
	rm -fr dist/cmdarg-$(VERSION)-$(RELEASE)*

dist: $(DISTFILE)

gitclean:
	git clean -df

test: tunit.txt

test-ci: junit.xml

# --- End phony targets

junit.xml: cmdarg.sh $(JUNIT_DEPS)
	AK_PREFIX=. $(PREFIX)/bin/shunit.sh -f junit -t tests > junit.xml

tunit.txt: cmdarg.sh $(JUNIT_DEPS)
	AK_PREFIX=. $(PREFIX)/bin/shunit.sh -f tunit -t tests | tee tunit.txt

version.sh:
	gitversion.sh > version.sh

$(DISTFILE): version.sh
	mkdir -p dist/
	mkdir dist/cmdarg-$(VERSION)-$(RELEASE) || rm -fr dist/cmdarg-$(VERSION)-$(RELEASE)
	rsync -aWH . --exclude=.git --exclude=dist ./dist/cmdarg-$(VERSION)-$(RELEASE)/
	cd dist && tar -czvf ../$@ cmdarg-$(VERSION)-$(RELEASE)

uninstall:
	rm -f $(PREFIX)/usr/lib/cmdarg.sh

install:
	mkdir -p $(PREFIX)/lib
	install ./cmdarg.sh $(PREFIX)/lib/cmdarg.sh

MANIFEST:
	echo $(PREFIX)/lib/cmdarg.sh > MANIFEST
