#!/bin/sh
set -ex

are_we_installed () {
if [ -f /nextcloud/config/config.php ]; then
  echo "config file already exists. "
  nc_installed="YES"
fi
}

check_db () {
if [ $DB_TYPE = sqlite ]; then
  db_status="ok"
  return
fi

check_version () {
NC_VERSION=`occ status --output=json | jq -r .version | awk -F. {'print $1'}`
}

db_status="notok"
counter=0
set +e
while [ $db_status = "notok" ] && [ $counter -le 30 ]; do
  php /usr/local/${PHP_CHK_FILE}
  if [ $? -ne 0 ]; then
    sleep 1
    counter=$(( $counter + 1 ))
    else db_status="ok"
  fi
done
}

are_we_upgraded () {
PHP_CHK_FILE=dbcheck.php
check_db
occ upgrade
check_version
if [ $ADD_INDEX_AUTO = "YES" ]; then
  occ db:add-missing-indices
fi
if [ $ADD_MIS_COL = "YES" ] && [ $NC_VERSION -gt 18 ] && [ $DB_TYPE != "sqlite" ]; then
  occ db:add-missing-columns
fi
set -e
}

install_nc () {
PHP_CHK_FILE=dbcheckenv.php
check_db
cp /usr/local/config.php /nextcloud/config/config.php
if [ -z ${NC_PASS} ]; then
  return
fi
/usr/local/bin/ncinstall.sh
set -e
occ config:import < /usr/local/bin/ncconf.json
occ config:system:set trusted_domains 1 --value=$DOMAIN
occ config:system:set memcache.local --value="\OC\Memcache\APCu"
occ config:system:set appstoreenabled --type boolean --value true
if [ $CRON_TYPE = "WEB" ]; then
  occ background:webcron
fi
if [ $AUTO_CONV_FC = "YES" ]; then
  occ db:convert-filecache-bigint
fi
if [ $ADD_INDEX_AUTO = "YES" ]; then
  occ db:add-missing-indices
fi
if [ $SET_URL = "YES" ]; then
  occ config:system:set overwrite.cli.url --value=$SITE_URL
fi
if [ $ENFORCE_HTTPS = "YES" ]; then
  occ config:system:set overwriteprotocol --value="https"
fi
if [ $SET_PROXY = "YES" ]; then
  occ config:system:set trusted_proxies 0 --value=$TRUSTED_PROXY
  # the below is needed to let curl based healthcheck working from within the container.
  occ config:system:set overwritecondaddr --value=$TRUSTED_PROXY
fi
}

check_installation_vars () {
for i in "${NC_PASS}"
  do if [ -z $i ]; then
    echo nextcloud automated installation needs variable '"NC_PASS"' to be specified
    echo "you can install nextcloud manually by visiting http://<hostname>:${HTTP_PORT}"
    return
  fi
done
if [ -z $DB_PASS ] && [ $DB_TYPE = "mysql" ]; then
  echo please set variable '"DB_PASS"' or use database type sqlite or postgres
  exit 1
fi
if [ $SET_PROXY = "YES" ] && [ -z $TRUSTED_PROXY ]; then
  echo please set an ip address for the proxyserver you use or set variable '"SET_PROXY"' to 'NO'
  exit 1
fi
if [ $SET_URL = "YES" ] && [ -z $SITE_URL ]; then
  echo please define variable '"SITE_URL"' e.g. https://www.mydomain.org or set variable '"SET_URL"' to 'NO'
  exit 1
fi
}
update_apps () {
occ app:update --all
}


am_i_webadm () {
if [ $(whoami) = apache ]; then
  nc_installed="NO"
  are_we_installed
  # Put the configuration and apps into volumes
  if [ $nc_installed = "NO" ]; then
    check_installation_vars
    install_nc
  fi
  if [ $nc_installed = "YES" ]; then
    if [ $NC_UP_AUTO = "YES" ]; then
    are_we_upgraded
    fi
    if [ $NC_APP_UP_AUTO = "YES" ]; then
    update_apps
    fi
  fi
fi
}

# define some conditions on whether we are installed or not
am_i_webadm
#startup
exec "$@"
