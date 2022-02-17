#!/bin/bash

# generate nextcloud-db .env files
NEXTCLOUD_DB_PROD_FILE="$1"
#NEXTCLOUD_PASSWORD=$(python3 -c "import secrets; import string; print(f''.join([secrets.choice(string.ascii_letters+string.digits) for x in range(32)]))")
NEXTCLOUD_PASSWORD="${MISTBORN_DEFAULT_PASSWORD}"
echo "MYSQL_ROOT_PASSWORD=$(pwgen 40 1)" > $NEXTCLOUD_DB_PROD_FILE
echo "MYSQL_PASSWORD=$(pwgen 40 1)" >> $NEXTCLOUD_DB_PROD_FILE
echo "MYSQL_DATABASE=nextcloud" >> $NEXTCLOUD_DB_PROD_FILE
echo "MYSQL_USER=nextcloud" >> $NEXTCLOUD_DB_PROD_FILE
chmod 600 $NEXTCLOUD_DB_PROD_FILE
