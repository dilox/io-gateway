VER?=$(shell git tag --points-at HEAD | head -1)
DOCKER_USER?=$(shell git remote | grep -v noiopen | grep -v pagopa | head -1)

.PHONY: preflight branch build test release release_mac snapshot all clean
branch:
	$(MAKE) build 
	$(MAKE) test

release:
	test -n "$(VER)"
	$(MAKE) IOSDK_VER=$(VER) DOCKER_USER=$(DOCKER_USER) build
	$(MAKE) test
	$(MAKE) IOSDK_VER=$(VER) DOCKER_USER=$(DOCKER_USER) push
	$(MAKE) IOSDK_VER=$(VER) DOCKER_USER=$(DOCKER_USER) -C iosdk/setup/linux
	$(MAKE) IOSDK_VER=$(VER) DOCKER_USER=$(DOCKER_USER) -C iosdk/setup/windows

release_mac:
	test -n "$(VER)"
	$(MAKE) IOSDK_VER=$(VER) DOCKER_USER=$(DOCKER_USER) -C iosdk/setup/mac

clean:
	-$(MAKE) -C admin clean
	-$(MAKE) -C ide clean
	-$(MAKE) -C iosdk clean
	-$(MAKE) -C scheduler clean
	
build: preflight
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C admin
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C ide
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C iosdk
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C scheduler

push:
	docker login
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C admin push
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C ide push
	$(MAKE) DOCKER_USER=$(DOCKER_USER) -C scheduler push

test:
	# test cli
	make -C iosdk test
	# test execution
	bash test.sh
	# test actions
	make -C admin/actions test
	# test scheduler
	make -C scheduler test

snapshot:
	date +%Y.%m%d.%H%M-snapshot >.snapshot
	git tag "$(shell cat .snapshot)"
	git push origin master --tags
	git tag -d "$(shell cat .snapshot)"

preflight:
	echo "checking required versions"
	node -v | grep v12
	python3 -V | grep 3.7
	go version | grep go1.13

