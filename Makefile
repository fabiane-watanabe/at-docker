# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Options:
#     AT_VERSION    - specify the AT version
#                     default: latest version
#     AT_MINOR      - specify a minor version (this will be used if AT_EXTRA is set)
#                     default: nothing
#     AT_EXTRA      - specify an extra value to add to the AT version (alpha1, beta2, rc1...)
#                     default: nothing
#     DISTRO_NAME   - specify the name of the distro (debian, ubuntu...)
#                     default: current distro
#     DISTRO_NICK   - specify the nickname/version of the distro (buster, focal, xenial...)
#                     default: current nickname/version
#     IMAGE_PROFILE - devel (default) or runtime
#     REPO          - specify the remote repository to get the AT packages
#                     default: http://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at
#     DOCKER_TOOL   - specify the container tool to use
#                     default: docker or podman

SHELL := /bin/bash

ifndef DOCKER_TOOL
    # Is there docker?
    DOCKER_TOOL := $(shell command -v docker)
    ifeq ($(DOCKER_TOOL),)
        # No docker, let try podman
        DOCKER_TOOL := $(shell command -v podman)
        ifeq ($(DOCKER_TOOL),)
            $(error Unable to find docker or podman command at PATH)
        endif
    endif
endif

# lsb_release must be installed
LSB_TOOL := $(shell command -v lsb_release)
ifeq ($(LSB_TOOL),)
    $(error Unable to find lsb_release command at PATH)
endif

CONFIG_ROOT := $(shell pwd)/configs

ifndef AT_VERSION
    AT_VERSION := $(shell basename $$(ls -d $(CONFIG_ROOT)/[1-9]*.[0-9] | tail -1))
    ifeq ($(AT_VERSION),)
        $(error Couldn't infer AT_VERSION variable, and no hint was given... Bailing out!)
    else
        $(warning AT_VERSION variable not informed... Using latest one ($(AT_VERSION)).)
    endif
endif

CONFIG := $(CONFIG_ROOT)/$(AT_VERSION)
HOST_ARCH := $(shell uname -m)
ifndef DISTRO_NAME
    DISTRO_NAME := $(shell $(LSB_TOOL) -i -s | tr [:upper:] [:lower:])
endif
ifndef DISTRO_NICK
    DISTRO_NICK := $(shell $(LSB_TOOL) -c -s | tr [:upper:] [:lower:])
endif

ifneq "$(HOST_ARCH)" "ppc64le"
    ifneq "$(HOST_ARCH)" "x86_64"
        $(error Unsupported host architecture ($(HOST_ARCH)) to build the image)
    else
        HOST_ARCH := amd64
    endif
endif

ifndef IMAGE_PROFILE
    IMAGE_PROFILE := devel
endif

DOCKER_FILE := $(CONFIG)/dockerfile-$(IMAGE_PROFILE)

IMAGE_TAG := at/$(AT_VERSION):$(DISTRO_NAME)_$(IMAGE_PROFILE)_$(HOST_ARCH)

ifndef REPO
    REPO := http://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at
endif

ifdef AT_EXTRA
    EXTRA := "-$(AT_EXTRA)"
    ifndef AT_MINOR
        AT_MINOR := 0
    endif
    MINOR := "-$(AT_MINOR)"
endif

.PHONY: all clean

all: $(DOCKER_FILE)
	@echo Build docker image with $(IMAGE_TAG) tag
	$(DOCKER_TOOL) build --build-arg ARCH=$(HOST_ARCH) \
                             --build-arg AT_VERSION=$(AT_VERSION) \
                             --build-arg DISTRO_NAME=$(DISTRO_NAME) \
                             --build-arg DISTRO_NICK=$(DISTRO_NICK) \
                             --build-arg EXTRA=$(EXTRA) \
                             --build-arg MINOR=$(MINOR) \
                             --build-arg REPO=$(REPO) \
                             -t $(IMAGE_TAG) -f $(DOCKER_FILE) $(CONFIG)
clean:
	@echo Remove docker image tagged $(IMAGE_TAG)
	$(DOCKER_TOOL) rmi $(IMAGE_TAG)
