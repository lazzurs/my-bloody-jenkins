.PHONY: default
LTS_VERSION_FILE = LTS_VERSION.txt
LTS_VERSION = `cat $(LTS_VERSION_FILE)`
DEFAULT_BUILD_ARGS = --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy) --build-arg no_proxy=$(no_proxy) --network=host

default: test-all

build-all: build-alpine build-debian build-jdk11

test-all: test-alpine test-debian test-jdk11

build-alpine:
	docker build --rm --force-rm -t ghcr.io/lazzurs/my-bloody-jenkins $(DEFAULT_BUILD_ARGS) --build-arg=FROM_TAG=$(LTS_VERSION)-alpine .

build-debian:
	docker build --rm --force-rm -t ghcr.io/lazzurs/my-bloody-jenkins $(DEFAULT_BUILD_ARGS) --build-arg=FROM_TAG=$(LTS_VERSION) .

build-jdk17:
	docker build --rm --force-rm -t ghcr.io/lazzurs/my-bloody-jenkins $(DEFAULT_BUILD_ARGS) --build-arg=FROM_TAG=$(LTS_VERSION)-jdk17 .

test-alpine: build-alpine
	bats tests

test-debian: build-debian
	bats tests

test-jdk17: build-jdk17
	bats tests

update-plugins:
	env python3 $(PWD)/get-latest-plugins.py
	git diff plugins.txt | grep  '^+' | sed 's|+||' | grep -v + | awk -F \: '{print "* ["$$1":"$$2"](https://plugins.jenkins.io/" $$1 ")"}'

release:
	$(eval NEW_INCREMENT := $(shell expr `git describe --tags --abbrev=0 | cut -d'-' -f2` + 1))
	git tag v$(LTS_VERSION)-$(NEW_INCREMENT)
	git push origin v$(LTS_VERSION)-$(NEW_INCREMENT)
