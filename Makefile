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

SHELL := /bin/bash

# Docker command must be installed
DOCKER_TOOL := $(shell command -v docker)
ifeq ($(DOCKER_TOOL),)
    $(error Unable to find docker command at PATH)
endif

# lsb_release must be installed
LSB_TOOL := $(shell command -v lsb_release)
ifeq ($(LSB_TOOL),)
    $(error Unable to find lsb_release command at PATH)
endif

CONFIG_ROOT := $(shell pwd)/configs

ifndef AT_CONFIGSET
    AT_CONFIGSET := $(shell basename $$(ls -d $(CONFIG_ROOT)/[1-9]*.[0-9] | tail -1))
    ifeq ($(AT_CONFIGSET),)
        $(error Couldn't infer AT_CONFIGSET variable, and no hint was given... Bailing out!)
    else
        $(warning AT_CONFIGSET variable not informed... Using latest one ($(AT_CONFIGSET)).)
    endif
endif

CONFIG := $(CONFIG_ROOT)/$(AT_CONFIGSET)
HOST_ARCH := $(shell uname -m)
DISTRO_NAME := $(shell $(LSB_TOOL) -i -s | tr [:upper:] [:lower:])

ifeq ($(HOST_ARCH),ppc64le)
    BUILD_ARCH := $(HOST_ARCH)
else ifeq ($(HOST_ARCH),x86_64)
# Image for cross compiler
    BUILD_ARCH := x86_64.ppc64le
else
    $(error Unsupported host architecture ($(HOST_ARCH)) to build the image)
endif

ifndef IMAGE_PROFILE
    IMAGE_PROFILE := devel
endif

DOCKER_FILE := $(CONFIG)/$(DISTRO_NAME)/Dockerfile-$(IMAGE_PROFILE)_$(BUILD_ARCH)

IMAGE_TAG := at/$(AT_CONFIGSET):$(DISTRO_NAME)_$(IMAGE_PROFILE)_$(BUILD_ARCH)

.PHONY: all clean

all: $(DOCKER_FILE)
	@echo Build docker image with $(IMAGE_TAG) tag
	$(DOCKER_TOOL) build -t $(IMAGE_TAG) -f $(DOCKER_FILE) $(CONFIG)
clean:
	@echo Remove docker image tagged $(IMAGE_TAG)
	$(DOCKER_TOOL) rmi $(IMAGE_TAG)
