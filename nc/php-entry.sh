#!/bin/sh
set -ex
are_we_installed () {
if [ -f /nextcloud/config/config.php ]; then
  echo "config file already exists. "
  nc_installed="yes"
fi
}

are_we_upgraded () {
# timeout check for db ?
#if nc -z -w 30 nexttest-db 3306 etc.
  mysql_status="notok"
  counter=0
  set +e
  while [ $mysql_status = "notok" ] && [ $counter -le 30 ]; do
    run-parts -u 0007 /home/webadm/ncup
    if [ $? -ne 0 ]; then
      sleep 1
      counter=$(( $counter + 1 ))
      else mysql_status="ok"
    fi
  done
set -e
#fi
}

install_nc () {
umask 0007
mysql_status="notok"
counter=0
set +e
while [ $mysql_status = "notok" ] && [ $counter -le 30 ]; do
  /usr/local/bin/ncinstall.sh
  if [ $? -ne 0 ]; then
    sleep 1
    counter=$(( $counter + 1 ))
  else mysql_status="ok"
  fi
done
set -e
php /nextcloud/occ config:import < /usr/local/bin/ncconf.json
php /nextcloud/occ config:system:set trusted_domains 1 --value=$DOMAIN
php /nextcloud/occ config:system:set memcache.local --value="\OC\Memcache\APCu"
if [ $CRON_TYPE = "WEB" ]; then
  php /nextcloud/occ background:webcron
fi
}

tunables () {
echo "MEMORY_LIMIT=${MEMORY_LIMIT}" > /home/webadm/.profile
}

am_i_webadm () {
if [ $(whoami) = webadm ]; then
  nc_installed="no"
  are_we_installed
  # Put the configuration and apps into volumes
  if [ $nc_installed = "no" ]; then
    umask 0007
    install_nc
    chmod 660 /nextcloud/config/config.php
    tunables
    exit 0
  fi
  if [ $nc_installed = "yes" ]; then
    are_we_upgraded
    tunables
    chmod 660 /nextcloud/config/config.php
    exit 0
  fi
fi
}

# define some conditions on whether we are installed or not
am_i_webadm
#startup
umask 0007
exec "$@"
