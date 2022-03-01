#!/bin/bash

ENV_FILE=/opt/mistborn/.env

# check that curl exists
if ! [ -x "$(command -v curl)" ]; then
    echo "Installing curl"
    sudo apt-get install -y curl
fi


if [ -f "${ENV_FILE}" ]; then
    export $(cat ${ENV_FILE} | xargs)
fi

HTTPD="404"
until [ "$HTTPD" == "200" ]; do
    echo "Waiting for Nextcloud to start...${HTTPD}"
    sleep 10 
    HTTPD=$(curl -A "Web Check" -sL --connect-timeout 3 -w "%{http_code}\n" "http://nextcloud.${MISTBORN_BASE_DOMAIN}" -o /dev/null)
done

echo "Nextcloud is running! Setting config.php variables."

docker-compose -f /opt/mistborn/extra/nextcloud.yml exec -T nextcloud su -p www-data -s /bin/sh -c "php /var/www/html/occ config:system:set verify_peer_off --value=true"
docker-compose -f /opt/mistborn/extra/nextcloud.yml exec -T nextcloud su -p www-data -s /bin/sh -c "php /var/www/html/occ config:system:set allow_local_remote_servers --value=true"
