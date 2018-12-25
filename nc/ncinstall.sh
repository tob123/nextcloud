#!/bin/sh
umask 0007
occ maintenance:install --database ${DB_TYPE} --database-name ${DB_NAME} --database-host ${DB_HOST} --database-user ${DB_USER} --database-pass ${DB_PASS} --admin-user ${NC_ADMIN} --admin-pass ${NC_PASS} --data-dir=/nc/data
