#!/bin/bash
# Copyright 2022 IBM Corporation
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

# Start container, run test script into container and them remove it.
at_version=$1
distro_name=$2
distro_nick=$3
image_tag=$4
container_tool=$5
tests_dir=$6

timestamp=`date -u +%Y-%m-%d_%H_%M_%S`
logfile=${tests_dir}/atdocker${at_version}_${distro_name}_${distro_nick}_\
${timestamp}.log

echo "`date` - Starting at-docker test. Running test script into container" \
    2>&1 | tee ${logfile} 

container_name=test_at${at_version}_${distro_name}_${distro_nick}

# Start container and run test script.
${container_tool} run -it  --name ${container_name} -v \
    ${tests_dir}:/usr/src/myapp:Z -w /usr/src/myapp ${image_tag}\
    /usr/src/myapp/ck_binaries.sh ${at_version} ${distro_name} 2>&1 \
    | tee ${logfile}

echo "Waiting until docker stops (test script finishes)"
${container_tool} wait ${container_name}

echo "Removing container..."
${container_tool} rm -v ${container_name}

echo "`date` Test finished" 

