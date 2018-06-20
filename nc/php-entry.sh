#!/bin/sh
set -ex
are_we_installed () {
if [ -f /nc/config/config.php ]; then
  echo "config file already exists. "
  nc_installed="yes"
fi
}

prep_env () {
ln -sf /nc/config/config.php /nextcloud/config/config.php
ln -sf /nc/apps2 /nextcloud/other_apps/
}

are_we_upgraded () {
# timeout check for db ?
#if nc -z -w 30 nexttest-db 3306 etc.
if [ ! -L /nextcloud/config/config.php ]; then
  prep_env
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
fi
}

install_nc () {
umask 0007
prep_env
mysql_status="notok"
counter=0
set +e
while [ $mysql_status = "notok" ] && [ $counter -le 30 ]; do
  php /nextcloud/occ maintenance:install --database ${DB_TYPE} --database-name ${DB_NAME} --database-host ${DB_HOST} --database-user ${DB_USER} --database-pass ${DB_PASS} --admin-user ${NC_ADMIN} --admin-pass {NC_PASS} --data-dir=/nc/data
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
# some stuff todo here. most is already in the .htaccess
#sed -i -e "s/<APC_SHM_SIZE>/$APC_SHM_SIZE/g" /etc/php7/conf.d/nc_apcu.ini \
#       -e "s/<OPCACHE_MEM_SIZE>/$OPCACHE_MEM_SIZE/g" /php/conf.d/nc_opccache.ini \
#       -e "s/<CRON_MEMORY_LIMIT>/$CRON_MEMORY_LIMIT/g" /etc/s6.d/cron/run \
#       -e "s/<CRON_PERIOD>/$CRON_PERIOD/g" /etc/s6.d/cron/run \
#       -e "s/<UPLOAD_MAX_SIZE>/$UPLOAD_MAX_SIZE/g" /nginx/conf/nginx.conf /php/etc/php-fpm.conf \
#       -e "s/<MEMORY_LIMIT>/$MEMORY_LIMIT/g" /php/etc/php-fpm.conf
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
    chmod 660 /nc/config/config.php
    tunables
    exit 0
  fi
  if [ $nc_installed = "yes" ]; then
    are_we_upgraded
    tunables
    # make pretty urls: https://docs.nextcloud.com/server/13/admin_manual/installation/source_installation.html?highlight=pretty%20url#pretty-urls
    if [ $SITE_URL ]; then
      occ config:system:set overwrite.cli.url --value="${SITE_URL}"
      occ config:system:set htaccess.RewriteBase --value="/"
      occ maintenance:update:htaccess
    fi
    chmod 660 /nc/config/config.php
    exit 0
  fi
fi
}

# define some conditions on whether we are installed or not
am_i_webadm
umask 0007
ln -sf /nc/config/config.php /nextcloud/config/config.php
ln -sf /nc/apps2 /nextcloud/other_apps/
exec "$@"
