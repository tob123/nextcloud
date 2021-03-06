FROM alpine:3.12
# install the PHP extensions we need
# see https://docs.nextcloud.com/server/15/admin_manual/installation/source_installation.html
###
ENV HTTP_PORT=8000 \
    UPLOAD_MAX_SIZE=10G \
    APC_SHM_SIZE=128M \
    OPCACHE_MEM_SIZE=128 \
    TZ=Etc/UTC
ARG NC_VER=X.Y.Z
ARG NC_URL=https://download.nextcloud.com/server/releases/nextcloud-
ARG GPG_nextcloud="2880 6A87 8AE4 23A2 8372 792E D758 99B9 A724 937A"
RUN set -ex; \
    apk add --no-cache \
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
    php7-openssl \
# required for specific apps
    php7-ldap \
    php7-bcmath \
    php7-ftp \
    php7-imap \
    php7-exif \
    php7-gmp \
    php7-imagick \
    imagemagick \
# caching stuff
    php7-opcache \
    php7-redis \
    php7-apcu \
# command line processing
    php7-pcntl \
# for samba / cifs php module
    libsmbclient \
# add json support for commandline processing
    jq \
#others
# php itself
    php7 \
# health monitor needs curl
    curl \
# webserver and php
    php7-apache2 \
#since alpine 3.10 gnu-libiconv should work from standard repo
    gnu-libiconv ; \
#iconv does not perfectly work from alpine stable. see also here: https://github.com/docker-library/php/issues/240
# the version from edge is ok though.
#    && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv; \
# make the image reproducable by dropping fontcache. see also https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=864082
    rm -rf /var/cache/fontconfig/
#    gnu-libiconv && \
# download nextcloud stuff
# some build dependencies to download and extract nextcloud and to compile the smbclient php module
RUN set -ex; \
    apk add --no-cache --virtual build-dependencies \
    # this is for downloading
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
    #get nextcloud and check signatures
    cd /tmp ; \
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
    rm -rf /tmp/smbclient 


RUN set -ex; \
    apk add --no-cache --virtual build-dependencies \
    # this is for downloading
    ca-certificates \
    openssl \
    curl \
    gnupg ;\
    # and the following is for compling smbclient
    update-ca-certificates ; \
    #get nextcloud and check signatures
    cd /tmp ; \
    curl -O ${NC_URL}${NC_VER}.tar.bz2.sha256 ; \
    curl -O ${NC_URL}${NC_VER}.tar.bz2.asc ; \
    curl -O ${NC_URL}${NC_VER}.tar.bz2.md5 ; \
    curl -O  ${NC_URL}${NC_VER}.tar.bz2 ; \
    md5sum -c nextcloud-${NC_VER}.tar.bz2.md5 < nextcloud-${NC_VER}.tar.bz2.md5 ;\
    sha256sum -c nextcloud-${NC_VER}.tar.bz2.sha256 < nextcloud-${NC_VER}.tar.bz2.sha256 ;\
    curl -O https://nextcloud.com/nextcloud.asc ;\
    gpg --import nextcloud.asc ;\
    FINGERPRINT="$(LANG=C gpg --verify nextcloud-${NC_VER}.tar.bz2.asc nextcloud-${NC_VER}.tar.bz2 2>&1 \
    | sed -n "s#Primary key fingerprint: \(.*\)#\1#p" | sed 's/  / /')";\
    if [ "${FINGERPRINT}" != "${GPG_nextcloud}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi ;\
    mkdir /nextcloud ;\
    apk del --purge build-dependencies ;\
    rm -rf /tmp/nextcloud.asc /tmp/nextcloud-${NC_VER}.tar.bz2.sha256 /tmp/nextcloud-${NC_VER}.tar.bz2.asc /tmp/${NC_VER}.tar.bz2.md5 /root/.gnupg ;\
    tar jxf /tmp/nextcloud-${NC_VER}.tar.bz2 -C /; \
    rm /tmp/nextcloud-${NC_VER}.tar.bz2

RUN set -ex; \
#    adduser -u $WEBADM_UID -D -G apache -g 'website administrator' -s /sbin/nologin webadm ; \
    sed -i "s/80/\$\{HTTP_PORT\}/g" /etc/apache2/httpd.conf ; \
    sed -i 's/logs\/error.log/\/proc\/self\/fd\/2/' /etc/apache2/httpd.conf ; \
    sed -i 's/logs\/access.log/\/proc\/self\/fd\/1/' /etc/apache2/httpd.conf; \
    if [ ! -d /run/apache2 ]; then mkdir /run/apache2; fi; \
    chown apache:apache /run/apache2; \
    chmod 700 /run/apache2; \
    mkdir -p /nc/data /nc/themes; \
    chown -R apache:apache /nc ; \
    chown -R apache:apache /nextcloud/config ; \
#    chown webadm /tmp/nextcloud-${NC_VER}.tar.bz2 ;\
    mkdir /usr/local/ncup
COPY index.php /var/www/localhost/htdocs/
COPY nc_opccache.ini nc_apcu.ini /etc/php7/conf.d/
COPY checkcontain*.sh ncinstall.sh php-entry-dev.sh occ ncconf.json /usr/local/bin/
COPY ncup /usr/local/ncup/
COPY config.php dbcheck.php dbcheckenv.php /usr/local/
COPY https_auto.conf remoteip.conf httpd-nc.conf cis.conf /etc/apache2/conf.d/
COPY limitexcept /root/
RUN set -ex; \
#   chmod +r /etc/php7/conf.d/nc_apcu.ini /etc/php7/conf.d/nc_opccache.ini; \
#    /usr/local/bin/occ /home/webadm; \
#    chmod +rx /usr/local/bin/occ /usr/local/bin/ncinstall.sh /usr/local/bin/occ /usr/local/bin/php-entry-dev.sh /usr/local/ncup/ncup; \
#    chmod +r /usr/local/bin/ncconf.json /usr/local/config.php /usr/local/dbcheckenv.php /usr/local/dbcheck.php; \
#    chmod +r /etc/apache2/conf.d/httpd-nc.conf /etc/apache2/conf.d/cis.conf; \
    #get suid and gid files out of the way.
    chmod -R g-s /var/log/apache2 /var/www/localhost/htdocs; \
    chmod -R u-s /usr/sbin/suexec; \
#sed -i 's/logs\/error.log/\/tmp\/logpipe/' /etc/apache2/httpd.conf ; \
#sed -i 's/logs\/access.log/\/tmp\/logpipe/' /etc/apache2/httpd.conf
# sooome hacks to get stdout logging working combined with su-exec
#CIS stuff for apache
#apply some cis baseline items for apache. nextcloud does not need most auth related modules:
    APACHECONF=/etc/apache2/httpd.conf; \
    sed -i 's/^LoadModule auth_basic_module/#LoadModule auth_basic_module/' ${APACHECONF}; \
    sed -i 's/^LoadModule authn_file_module/#LoadModule authn_file_module/' ${APACHECONF}; \
    sed -i 's/^LoadModule authz_user_module/#LoadModule authz_user_module/' ${APACHECONF}; \
    sed -i 's/^LoadModule authz_groupfile_module/#LoadModule authz_groupfile_module/' ${APACHECONF}; \
#deactivate status
    sed -i 's/^LoadModule status_module/#LoadModule status_module/' ${APACHECONF}; \
#deactivate autoindex
    sed -i 's/^LoadModule autoindex_module/#LoadModule autoindex_module/' ${APACHECONF}; \
#drop some config files related to modules not needed:
    rm /etc/apache2/conf.d/userdir.conf; \
    rm /etc/apache2/conf.d/info.conf; \
#set options to none for default directories as recommended in 1.5
    sed -i 's/^    Options .*/    Options None/' ${APACHECONF}; \
#1.5.6 removal of test-cgi
    rm /var/www/localhost/cgi-bin/test-cgi; \
#1.5.7: set limit to valid http requests
    sed -i '/\<Directory /r /root/limitexcept' ${APACHECONF}; \
    rm /root/limitexcept; \
#1.6 increase logging verbosity
    sed -i 's/^LogLevel.*/LogLevel notice core:info/' ${APACHECONF}; \
#1.7 ssl is done elsewhere (not in this container)
#1.8
    sed -i 's/^ServerTokens.*/ServerTokens Prod/' ${APACHECONF}; \
    sed -i 's/^ServerSignature.*/ServerSignature Off/' ${APACHECONF}; \
    sed -i 's/^Timeout.*/Timeout 10/' /etc/apache2/conf.d/default.conf; \
# some php items
PHPCONF=/etc/php7/php.ini; \
#hide php version from headers:
sed -i 's/expose_php = On/expose_php = Off/' $PHPCONF; \
#make resource limits configurable via environment variables
sed -i "s/memory_limit = 128M/memory_limit = \$\{MEMORY_LIMIT\}/" $PHPCONF; \
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = \$\{UPLOAD_MAX_SIZE\}/" $PHPCONF; \

### new stuff to move to only apache user

mkdir /nextcloud/apps2; \
chown apache /nextcloud/apps2


USER apache
RUN  chmod 770 /nextcloud/config; \
#     mkdir /nextcloud/apps2; \
     chmod 770 /nextcloud/apps2
VOLUME /nc/data /nextcloud/config /nextcloud/apps2
EXPOSE $HTTP_PORT
ENV DOMAIN=localhost \
    ADD_INDEX_AUTO="YES" \
    DB_TYPE=sqlite \
    DB_HOST=localhost \
    CRON_TYPE=WEB \
    SITE_URL="" \
    NC_ADMIN="admin" \
    NC_PASS="" \
    NC_UP_AUTO="YES" \
    NC_APP_UP_AUTO="YES" \
    DB_USER="nextcloud" \
    DB_PASS="" \
    DB_NAME="nextcloud" \
    AUTO_CONV_FC="YES" \
    MEMORY_LIMIT=512M \
    SET_URL="NO" \
    ENFORCE_HTTPS="NO" \
    SET_PROXY="NO" \
    TRUSTED_PROXY="" \
    ADD_MIS_COL="YES" \
    REM_INT_PROX_IP="172.16.0.0/12" \
    #another step to get iconv working
    LD_PRELOAD=/usr/lib/preloadable_libiconv.so
HEALTHCHECK CMD /usr/local/bin/checkcontainer.sh
LABEL description="Nextcloud Docker container without root gosu sudo or other wrappers that use root" \
      nextcloud="Nextcloud v${NC_VER}" \
      maintainer="Appelo Solutions <tob@nice.eu>"
ENTRYPOINT ["php-entry-dev.sh"]
CMD ["httpd", "-DFOREGROUND"]
    
