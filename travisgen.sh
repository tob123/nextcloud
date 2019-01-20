#!/bin/bash
set -e
# what major versions to support
NC_MAJOR="13 14 15"
#get all available versions
curl -sS https://download.nextcloud.com/server/releases/?F=0 | awk {' print $3'} | awk -F- {'print $2'} | awk -F. {'print $1"."$2"."$3'} | grep "^[0-9].*\.[0-9]$" | sort -n | uniq > versions
if [ ! -s versions ];then echo "nextcloud version query failed. exiting";exit 1;fi 
#clean existing travis file
sed -i '/VERSION=/d' .travis.yml
#now fill the build matrix in the yml file
for i in $NC_MAJOR
  do #echo $i
  for j in $(cat versions | grep ^${i})
  do #echo $j
  sed -i "/^  matrix:/a \ \ - VERSION=${j}" .travis.yml
  done
done
