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
#
# This script install redis and neo4j database, 
# do some db operations like store and read data.
# Then, check if these db binaries are linked to AT libraries.

# Install package and check if it was correctly installed
install_package(){
	echo "Installing ${1^}." 
	if [[ ${3} == "debian" || ${3} == "ubuntu" ]];then
		apt update
		apt install --assume-yes=TRUE $1
	else
		echo "DISTRO NOT SUPPORTED FOR THESE TESTS. ABORTING."
		exit
	fi

	local=`which $2`
	if [ -z $local ];then
		echo "ERROR INSTALLING {$1^^}. ABORTING TEST."
		exit      
	fi
	echo "${1^} installed."
}

# Start redis server, and check if it responds to client command
start_redis(){
	echo "Starting redis.."
	redis-server /etc/redis/redis.conf

	# Ping server and check if it responds.
	for i in {1..5}; do
		res=`redis-cli PING`    
		if [ "$res" != 'PONG' ]; then 
			echo "Error starting redis. Retry ... attempt \
${i} of 5"
		else
			return
		fi   
		sleep 1
	done
	echo "ERROR STARTING REDIS SERVER. ABORTING TEST."
	exit
}

# Send store and geospatial commands and check if it`s correct.
check_redisdb(){

	# Store and read key-value.
	ins=`redis-cli set 'x' 'y'`
	var=`redis-cli get 'x'`
	if [ "$var" != 'y' ]; then 
		echo "ERROR IN REDIS TEST (STORING VALUE TEST). \
ABORTING TEST."
		exit 
	fi    

	# Store 2 known geo points and check if geodist redis command 
	# is executed correctly.
	add_geo=`redis-cli GEOADD Brazil  -46.625290  -23.533773\
		"SaoPaulo" -43.196388 -22.908333 "RiodeJaneiro"`
	dist=`redis-cli GEODIST Brazil  SaoPaulo RiodeJaneiro`
	
	if [ "$dist" != '357314.9411' ]; then 
		echo "ERROR IN REDIS TEST (GEOTEST). ABORTING TEST."
		exit 
	fi
	echo "REDIS TEST SUCCEEDED."
}

# Check if binaries are linked to AT libraries.
check_bin_dependencies(){
	echo "Checking shared libraries of ${2}"
	at_folder="/opt/at$1"

	if [[ ! -d ${at_folder} ]]; then
		echo "ERROR: AT FOLDER (${at_folder}) NOT FOUND. ABORTING TEST."
		exit
	fi

	bin_name=$2

	#Check binary dependencies
	path_bin=`which $bin_name`  

	oldIFS="$IFS"
	IFS=$'\n' 
	dependencies=($(ldd $path_bin | tr -d '=>'))
	IFS="$oldIFS"   

	# Check if lib required exists in ATx.y folder, if so, check 
	# if binary is loading from there.
	for (( i=0; i<${#dependencies[@]}; i++ )); 
   	do          
		lib_dep=(${dependencies[i]})
		echo "Checking ${lib_dep[0]} => ${lib_dep[1]}"

		lib_path=$(find $at_folder/ -wholename \
			 *"${lib_dep[0]}" | wc -l)

		if [[ $lib_path -gt 0 ]];then
			if [[ ${lib_dep[1]} != "$at_folder"* ]];then            
				cat << EOF
ERROR CHECKING  ${bin_name^^} DEPENDENCIES!! 
IT SHOULD LOAD LIBRARY '${lib_dep[0]^^}' FROM '${at_folder^^}'.
BUT IT LOADS FROM '${lib_dep[1]^^}'. ABORTING TEST.'
EOF
				exit 
			fi
		fi  
	done
}

# Install neo4j database.
install_neo4j()
{
	echo "Installing neo4j database."
	if [[ (${1,,} == "debian") || (${1,,} == "ubuntu") ]]; then  
		curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key |\
			 apt-key add -    
		echo 'deb https://debian.neo4j.com stable 4.4' |\
			tee -a /etc/apt/sources.list.d/neo4j.list
	
		apt-get update
	
	else
		echo "DISTRO NOT SUPPORTED FOR THESE TESTS. ABORTING."
		exit
	fi

	install_package 'neo4j' 'neo4j' ${1} 
	return $? 
}

# Change neo4j password and start it.
start_neo4j(){
	neo4j-admin set-initial-password neo4j    
	neo4j start
}

# Store data into neo4j and search for it.
check_neo4j()
{
	echo "Checking Neo4j."   

	for i in {1..5}; do 
		res=$( cypher-shell -u neo4j -p neo4j "create(a:Person{name:\
'John John',alias :'JJ'}) return a.name;" )
		echo "Data stored in chyper" $res
		if [[ -z $res ]];then 
			cat << EOF 
Error trying to connect to neo4j server. 
Connection refused. Maybe server is not ready yet.  
Retry...... (attempt $i of 5)
EOF
			status=$(neo4j status)
			echo $status
			if [[ $status = *"not running"* ]];then
				echo "ERROR STARTING NEO4J. ABORTING TEST."
				exit 
			fi
			sleep 5
		else 
			break    
		fi
	done

	res=`cypher-shell -u neo4j -p neo4j "match (n:Person) where\
 n.alias='JJ' return n;"`      

	if [[ -z "$res" ]];then 
		echo "ERROR IN NEO4J TEST. ABORTING TEST."
		exit 
	fi

	echo "NEO4J TEST SUCCEEDED."
}

at_version=$1
at_distro=$2

# Testing AT using neo4j database
install_neo4j $at_distro 
check_bin_dependencies $at_version 'java'
start_neo4j
check_neo4j

# Testing AT by redis database
install_package 'redis' 'redis-server' ${at_distro}
start_redis
check_bin_dependencies $at_version 'redis-server' 
check_redisdb

echo "`date` - ALL TESTS SUCCEEDED!!!!!!"
