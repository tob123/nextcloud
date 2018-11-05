ARG ALPINE_VER=3.7
FROM alpine:${ALPINE_VER}
# we need php 7.1 because nextcloud has a dependency on mcrypt for php saml
# install the PHP extensions we need
# see https://docs.nextcloud.com/server/12/admin_manual/installation/source_installation.html
###
ENV HTTP_PORT=8000 \
    WEBADM_UID=3000
COPY httpd-foreground /usr/local/bin/
COPY limitexcept /root/
RUN apk --no-cache add \
    php7-apache2 \
    apache2 \
    php7 \
    curl; \
    adduser -u $WEBADM_UID -D -G apache -g 'website administrator' -s /sbin/nologin webadm ; \
    sed -i "s/80/${HTTP_PORT}/g" /etc/apache2/httpd.conf ; \
    sed -i 's/logs\/error.log/\/proc\/self\/fd\/2/' /etc/apache2/httpd.conf ; \
    sed -i 's/logs\/access.log/\/proc\/self\/fd\/1/' /etc/apache2/httpd.conf; \
    mkdir /run/apache2; \
    chown apache:apache /run/apache2; \
    chmod 700 /run/apache2; \
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
    chmod 755 /usr/local/bin/httpd-foreground
LABEL description="Apache/php Docker container without root gosu sudo or other wrappers that use root" \
      ALPINE="Alpine v${ALPINE_VER}" \
      maintainer="Appelo Solutions <tob@nice.eu>"

USER apache
CMD ["httpd-foreground"]
