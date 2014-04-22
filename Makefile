VERSION:=$(shell if [ -d .git ]; then bash -c 'gitversion.sh | grep "^MAJOR=" | cut -d = -f 2'; else source version.sh && echo $$MAJOR ; fi)
RELEASE:=$(shell if [ -d .git ]; then bash -c 'gitversion.sh | grep "^BUILD=" | cut -d = -f 2'; else source version.sh && echo $$BUILD ; fi)
DISTFILE=./dist/cmdarg-$(VERSION)-$(RELEASE).tar.gz
SPECFILE=cmdarg.spec
ifndef RHEL_VERSION
	RHEL_VERSION=5
endif
ifeq ($(RHEL_VERSION),5)
        MOCKFLAGS=--define "_source_filedigest_algorithm md5" --define "_binary_filedigest_algorithm md5"
endif

RHEL_RELEASE:=$(RELEASE).el$(RHEL_VERSION)
SRPM=cmdarg-$(VERSION)-$(RHEL_RELEASE).src.rpm
RPM=cmdarg-$(VERSION)-$(RHEL_RELEASE).noarch.rpm
RHEL_DISTFILE=./dist/cmdarg-$(VERSION)-$(RHEL_RELEASE).tar.gz

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

version.sh:
	gitversion.sh > version.sh

$(DISTFILE): version.sh
	mkdir -p dist/
	mkdir dist/cmdarg-$(VERSION)-$(RELEASE) || rm -fr dist/cmdarg-$(VERSION)-$(RELEASE)
	rsync -aWH . --exclude=.git --exclude=dist ./dist/cmdarg-$(VERSION)-$(RELEASE)/
	cd dist && tar -czvf ../$@ cmdarg-$(VERSION)-$(RELEASE)

$(RHEL_DISTFILE): $(DISTFILE)
	cd dist && ln -s .$(DISTFILE) .$(RHEL_DISTFILE)

./dist/$(SRPM): $(RHEL_DISTFILE)
	rm -fr ./dist/$(SRPM)
	mock --buildsrpm --verbose --spec $(SPECFILE) $(MOCKFLAGS) --sources ./dist/ --resultdir ./dist/ --define "version $(VERSION)" --define "release $(RHEL_RELEASE)"

./dist/$(RPM): ./dist/$(SRPM)
	rm -fr ./dist/$(RPM)
	mock --verbose -r epel-$(RHEL_VERSION)-noarch ./dist/$(SRPM) --resultdir ./dist/ --define "version $(VERSION)" --define "release $(RHEL_RELEASE)"

uninstall:
	rm -f $(PREFIX)/usr/lib/cmdarg.sh


install:
	mkdir -p $(PREFIX)/usr/lib
	install ./cmdarg.sh $(PREFIX)/usr/lib/cmdarg.sh

MANIFEST:
	echo /usr/lib/cmdarg.sh > MANIFEST
