BASEPATH := $(realpath .)
export BASEPATH

# Set to 1 to use static linking.
STATIC :=
PKG    := ./...

# Determine the user ID and group ID to be used within docker. If using Docker
# Toolbox such as on Darwin, it will map to 1000:50.
user   := $(shell id -u)
group  := $(shell id -g)
UNAMES := $(shell uname -s)
ifeq ($(UNAMES),Darwin)
user  := 1000
group := 50
endif

DOCKER_FLAGS := --rm -v ${BASEPATH}:${BASEPATH} -w ${BASEPATH} -e IN_DOCKER=1 -e TMPDIR=/tmp -e GOPATH=${GOPATH}
DOCKER_USER  := --user=${user}\:${group}
DOCKER_IMAGE := apcera/kurma-kernel
DOCKER        = docker run ${DOCKER_FLAGS} ${DOCKER_USER} ${DOCKER_IMAGE}

#
# Resources --- RUN THIS FIRST!
#
.PHONY: download
download: ## Download common pre-built assets from Kurma's CI
	@echo 'Downloading buildroot.tar.gz'
	@curl -L -o bin/buildroot.tar.gz http://ci.kurma.io/repository/download/Artifacts_ACIs_Buildroot/master.tcbuildtag/buildroot.tar.gz?guest=1
	@echo 'Downloading busybox.aci'
	@curl -L -o bin/busybox.aci http://ci.kurma.io/repository/download/Artifacts_ACIs_Busybox/master.tcbuildtag/busybox.aci?guest=1


## busybox
bin/buildroot.tar.gz:
	$(DOCKER) ./build/misc/buildroot/build.sh $@
bin/busybox.aci: bin/buildroot.tar.gz
	$(DOCKER) ./build/aci/busybox/build.sh $@
.PHONY: busybox-aci
busybox-aci: bin/busybox.aci

## cni-ovsv1-netplugin
bin/cni-ovsv1-netplugin-setup: build/aci/cni-ovsv1-netplugin/setup.c
	$(DOCKER) gcc -static -o ${BASEPATH}/$@ ./build/aci/cni-ovsv1-netplugin/setup.c
bin/cni-ovsv1-netplugin.aci: bin/busybox.aci bin/cni-ovsv1-netplugin-setup
	$(DOCKER) ./build/aci/cni-ovsv1-netplugin/build.sh $@
.PHONY: cni-ovsv1-netplugin-aci
cni-netplugin-aci: bin/cni-ovsv1-netplugin.aci
