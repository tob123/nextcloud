#!/bin/bash
set -e
# what major versions to support
NC_MAJOR="17 18 19"
NC_LATEST="19"
#get all available versions
curl -sS https://download.nextcloud.com/server/releases/?F=0 | awk {' print $3'} | awk -F- {'print $2'} | awk -F. {'print $1"."$2"."$3'} | grep "^[0-9].*\.[0-9]" | sort -n | uniq > versions
if [ ! -s versions ];then echo "nextcloud version query failed. exiting";exit 1;fi 
#clean existing travis file
sed -i '/VERSION=/d' .travis.yml
sed -i '/LATEST_MINOR=/d' .travis.yml
#now fill the build matrix in the yml file
for i in $NC_MAJOR
  do #echo $i
  LATEST_MINOR=$(cat versions | grep ^${i} | sort -n | tail -1)
  for j in $(cat versions | grep ^${i}); do 
    if [[ $NC_LATEST = $i && $LATEST_MINOR = $j ]] ; then
      sed -i "/^  matrix:/a \ \ - VERSION=${j} VERSION_MAJOR=${i} LATEST=true" .travis.yml
    fi
    if [[ $LATEST_MINOR = $j && $NC_LATEST != $i ]]; then
      sed -i "/^  matrix:/a \ \ - VERSION=${j} VERSION_MAJOR=${i}" .travis.yml
    fi
  done
done
