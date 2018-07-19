FROM alpine:3.7
# we need php 7.1 because nextcloud has a dependency on mcrypt for php saml

# entrypoint.sh and cron.sh dependencies
# install the PHP extensions we need
# see https://docs.nextcloud.com/server/12/admin_manual/installation/source_installation.html
# questions / remarkds:
# do we need php itself ?
# arrange updating of packages (and clean cache afterwards)
# remove useless --no-cache parameter since this is the default anyway
###
ENV HTTP_PORT=8000 \
    UPLOAD_MAX_SIZE=10G \
    APC_SHM_SIZE=128M \
    OPCACHE_MEM_SIZE=128 \
    MEMORY_LIMIT=512M \
    TZ=Etc/UTC
RUN set -ex; \
    \
    apk update && apk upgrade ; \
    apk add \
# required packages
    php7-ctype \
    php7-dom \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-xml \
    php7-mbstring \
    php7-posix \
    php7-simplexml \
    php7-xmlreader \
    php7-xmlwriter \
    php7-zip \
    php7-zlib \
# for db
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-pdo_pgsql \
#recommended
    php7-curl \
    php7-fileinfo \
    php7-bz2 \
    php7-intl \
    php7-mcrypt \
    php7-openssl \
# required for specific apps
    php7-ldap \
    php7-ftp \
    php7-imap \
    php7-exif \
    php7-gmp \
    php7-imagick \
# caching stuff
    php7-opcache \
    php7-redis \
    php7-apcu \
# command line processing
    php7-pcntl \
# for samba / cifs php module
    libsmbclient \
#others
# php itself
    php7
# arrange webserver
RUN set -ex; \
    \
    apk add php7-apache2 ; \
    apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
# download nextcloud stuff
ARG NC_VER=13.0.4
ARG NC_URL=https://download.nextcloud.com/server/releases/nextcloud-
ARG GPG_nextcloud="2880 6A87 8AE4 23A2 8372 792E D758 99B9 A724 937A"
# some build dependencies to download and extract nextcloud and to compile the smbclient php module
RUN set -ex; \
    \
    apk add --virtual build-dependencies \
    # this is for downloading
    ca-certificates \
    openssl \
    curl \
    gnupg \
    # and the following is for compling smbclient
    autoconf \
    automake \
    file \
    g++ \
    gcc \
    make \
    php7-dev \
    re2c \
    samba-dev \
    zlib-dev \
    git ;\
    update-ca-certificates ; \
    cd /tmp ; \
    curl -O ${NC_URL}${NC_VER}.tar.bz2.sha256 ; \
    curl -O ${NC_URL}${NC_VER}.tar.bz2.asc ; \
    curl -O ${NC_URL}${NC_VER}.tar.bz2.md5 ; \
    curl -O  ${NC_URL}${NC_VER}.tar.bz2 ; \
    md5sum -c nextcloud-${NC_VER}.tar.bz2.md5 < nextcloud-${NC_VER}.tar.bz2.md5 ;\
    sha256sum -c nextcloud-${NC_VER}.tar.bz2.sha256 < nextcloud-${NC_VER}.tar.bz2.sha256 ;\
    curl -O https://nextcloud.com/nextcloud.asc ;\
    gpg --import nextcloud.asc ;\
#    gpg -q --verify nextcloud-${NC_VER}.tar.bz2.asc nextcloud-${NC_VER}.tar.bz2 ;\
    FINGERPRINT="$(LANG=C gpg --verify nextcloud-${NC_VER}.tar.bz2.asc nextcloud-${NC_VER}.tar.bz2 2>&1 \
    | sed -n "s#Primary key fingerprint: \(.*\)#\1#p" | sed 's/  / /')";\
    if [ "${FINGERPRINT}" != "${GPG_nextcloud}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi ;\
    mkdir /nextcloud ;\
    git clone git://github.com/eduardok/libsmbclient-php.git /tmp/smbclient ;\
    cd /tmp/smbclient ;\
    phpize7 ;\
    ./configure --with-php-config=/usr/bin/php-config7 ;\
    make ;\
    make install ;\
#make install just seems to copy resulted module from /tmp/smbclient/modules to /etc/php7/conf.d/
# so could be cleaner via  multistage build here and use copy from...
    echo "extension="smbclient.so"" > /etc/php7/conf.d/00_smbclient.ini ;\
    apk del --purge build-dependencies ;\
    rm -rf /tmp/smbclient /tmp/nextcloud.asc /tmp/nextcloud-${NC_VER}.tar.bz2.sha256 /tmp/nextcloud-${NC_VER}.tar.bz2.asc /tmp/${NC_VER}.tar.bz2.md5 /root/.gnupg
RUN set -ex; \
    \
    adduser -D -G apache -g 'website administrator' -s /sbin/nologin webadm ; \
    sed -i "s/80/${HTTP_PORT}/g" /etc/apache2/httpd.conf ; \
    sed -i 's/logs\/error.log/\/proc\/self\/fd\/2/' /etc/apache2/httpd.conf ; \
    sed -i 's/logs\/access.log/\/proc\/self\/fd\/1/' /etc/apache2/httpd.conf; \
    mkdir /run/apache2; \
    chown apache:apache /run/apache2; \
    mkdir -p /nc/data /nc/config /nc/apps2 /nc/themes; \
    tar jxf /tmp/nextcloud-${NC_VER}.tar.bz2 -C /; \
    chown -R webadm:apache /nc ; \
    chown -R webadm:apache /nextcloud ; \
    chown webadm /tmp/nextcloud-${NC_VER}.tar.bz2 ;\
    rm /tmp/nextcloud-${NC_VER}.tar.bz2 ;\
    mkdir /home/webadm/ncup
COPY index.php /var/www/localhost/htdocs/
COPY nc_opccache.ini nc_apcu.ini /etc/php7/conf.d/
COPY checkcontainer.sh php-entry.sh occ ncconf.json /usr/local/bin/
COPY ncup /home/webadm/ncup/
RUN chown -R webadm /etc/php7/conf.d/nc_apcu.ini /etc/php7/conf.d/nc_opccache.ini \
    /usr/local/bin/occ /home/webadm; \
    chmod +x /usr/local/bin/occ /usr/local/bin/php-entry.sh; \
    chmod -R g-s /home/webadm /var/log/apache2 /var/www/localhost/htdocs; \
    chmod -R u-s /usr/sbin/suexec
#sed -i 's/logs\/error.log/\/tmp\/logpipe/' /etc/apache2/httpd.conf ; \
#sed -i 's/logs\/access.log/\/tmp\/logpipe/' /etc/apache2/httpd.conf
# sooome hacks to get stdout logging working combined with su-exec
USER webadm
RUN  chmod 770 /nextcloud/config; \
     mkdir /nextcloud/other_apps; \
     chmod 770 /nextcloud/other_apps
VOLUME /nc/data /nc/config /nc/apps2
COPY httpd-nc.conf /etc/apache2/conf.d/
EXPOSE $HTTP_PORT
ENV DOMAIN=localhost \
    DB_TYPE=sqlite3 \
    DB_HOST=localhost \
    CRON_TYPE=WEB \
    SITE_URL="" \
    NC_ADMIN="" \
    NC_PASS="" \
    DB_USER="" \
    DB_PASS="" \
    LD_PRELOAD=/usr/lib/preloadable_libiconv.so
LABEL description="Nextcloud Docker container without root gosu or sudo" \
      nextcloud="Nextcloud v${NC_VER}" \
      maintainer="Appelo Solutions <tob@nice.eu>"
ENTRYPOINT ["php-entry.sh"]
CMD ["httpd", "-DFOREGROUND"]
HEALTHCHECK CMD /usr/local/bin/checkcontainer.sh
    
