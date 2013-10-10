VERSION:=$(shell if [ -d .git ]; then bash -c 'gitversion.sh | grep "^MAJOR=" | cut -d = -f 2'; else source version.sh && echo $$MAJOR ; fi)
RELEASE:=$(shell if [ -d .git ]; then bash -c 'gitversion.sh | grep "^BUILD=" | cut -d = -f 2'; else source version.sh && echo $$BUILD ; fi)
DISTFILE=./dist/cmdarg-$(VERSION)-$(RELEASE).tar.gz
SPECFILE=cmdarg.spec
SRPM=cmdarg-$(VERSION)-$(RELEASE).src.rpm
ifndef RHEL_VERSION
	RHEL_VERSION=5
endif
RPM=cmdarg-$(VERSION)-$(RELEASE).noarch.rpm

ifndef PREFIX
	PREFIX=''
endif

DISTFILE_DEPS=$(shell find . -type f | grep -Ev '\.git|\./dist/|$(DISTFILE)')

all: ./dist/$(RPM)

# --- PHONY targets

.PHONY: clean srpm rpm gitclean dist
clean:
	rm -f $(DISTFILE)
	rm -fr dist/cmdarg-$(VERSION)-$(RELEASE)*

dist: $(DISTFILE)

srpm: ./dist/$(SRPM)

rpm: ./dist/$(RPM) ./dist/$(SRPM)

gitclean:
	git clean -df

# --- End phony targets

# This was borrowed from distiller, and I think it's to prevent version.sh
# from updating unnecessarily
version.sh:
	if [ ! -d .git ] && [ -f version.sh ]; then echo "No git, keeping old version.sh" ; fi ; \
	if [ ! -d .git ] && [ ! -f version.sh ]; then echo "No git and no version.sh, you're boned"; exit 1; fi ; \
	if [ -d .git ] ; then \
		bash ./gitversion.sh > tmpversion.sh && \
		VERSIONSHA=$$(openssl sha1 version.sh | cut -d = -f 2) ; \
		TMPVERSIONSHA=$$(openssl sha1 tmpversion.sh | cut -d = -f 2) ; \
		if [ ! -e version.sh ] || [ "$$VERSIONSHA" != "$$TMPVERSIONSHA" ]; then \
			mv tmpversion.sh version.sh; \
		fi; \
	fi

$(DISTFILE): version.sh
	mkdir -p dist/
	mkdir dist/cmdarg-$(VERSION)-$(RELEASE) || rm -fr dist/cmdarg-$(VERSION)-$(RELEASE)
	rsync -aWH . --exclude=.git --exclude=dist ./dist/cmdarg-$(VERSION)-$(RELEASE)/
	cd dist && tar -czvf ../$@ cmdarg-$(VERSION)-$(RELEASE)

./dist/$(SRPM): $(DISTFILE)
	rm -fr ./dist/$(SRPM)
	mock --buildsrpm --spec $(SPECFILE) --sources ./dist/ --resultdir ./dist/ --define "version $(VERSION)" --define "release $(RELEASE)"

./dist/$(RPM): ./dist/$(SRPM)
	rm -fr ./dist/$(RPM)
	mock -r epel-$(RHEL_VERSION)-noarch ./dist/$(SRPM) --resultdir ./dist/ --define "version $(VERSION)" --define "release $(RELEASE)"

uninstall:
	rm -f $(PREFIX)/usr/lib/cmdarg.sh


install:
	mkdir -p $(PREFIX)/usr/lib
	install ./cmdarg.sh $(PREFIX)/usr/lib/cmdarg.sh

MANIFEST:
	echo /usr/lib/cmdarg.sh > MANIFEST
