#!/bin/bash

#### ENV file

VAR_FILE=/opt/mistborn/.env
DJANGO_PROD_FILE=/opt/mistborn/.envs/.production/.django

# run migrations
/opt/mistborn/scripts/env/migrations/run_migrations.sh


# load env variables
source /opt/mistborn/scripts/subinstallers/platform.sh

# setup env file
echo "" | sudo tee ${VAR_FILE}
sudo chown mistborn:mistborn ${VAR_FILE}
sudo chmod 600 ${VAR_FILE}

# MISTBORN_BASE_DOMAIN
if [[ -f "$DJANGO_PROD_FILE" ]] && grep -q -wi "MISTBORN_BASE_DOMAIN" "${DJANGO_PROD_FILE}" ; then

    MISTBORN_BASE_DOMAIN=$(grep -e "MISTBORN_BASE_DOMAIN=.*" ${DJANGO_PROD_FILE} | awk -F"=" '{print $2}')
else
    MISTBORN_BASE_DOMAIN=mistborn
fi

echo "MISTBORN_BASE_DOMAIN=${MISTBORN_BASE_DOMAIN}" | sudo tee -a ${VAR_FILE}

# MISTBORN_BIND_IP
# MISTBORN_DNS_BIND_IP
if [[ -f "$DJANGO_PROD_FILE" ]] && grep -q -wi "MISTBORN_BIND_IP" "${DJANGO_PROD_FILE}" ; then

    MISTBORN_BIND_IP=$(grep -e "MISTBORN_BIND_IP=.*" ${DJANGO_PROD_FILE} | awk -F"=" '{print $2}')
else
    MISTBORN_BIND_IP=10.2.3.1
fi

echo "MISTBORN_BIND_IP=${MISTBORN_BIND_IP}" | sudo tee -a ${VAR_FILE}
echo "MISTBORN_DNS_BIND_IP=${MISTBORN_BIND_IP}" | sudo tee -a ${VAR_FILE}

# Update DNS settings
echo "address=/.${MISTBORN_BASE_DOMAIN}/${MISTBORN_BIND_IP}" | sudo tee /opt/mistborn_volumes/base/pihole/etc-dnsmasqd/02-lan.conf
echo "address=/${MISTBORN_BASE_DOMAIN}/${MISTBORN_BIND_IP}" | sudo tee /opt/mistborn_volumes/base/pihole/etc-dnsmasqd/02-lan.conf

sudo sed -i "s/#name_servers.*/name_servers=${MISTBORN_BIND_IP}/" /etc/resolvconf.conf
sudo sed -i "s/name_servers.*/name_servers=${MISTBORN_BIND_IP}/" /etc/resolvconf.conf


# MISTBORN_TAG

GIT_BRANCH=$(git -C /opt/mistborn symbolic-ref --short HEAD || echo "master")
MISTBORN_TAG="latest"
if [ "$GIT_BRANCH" != "master" ]; then
    MISTBORN_TAG="test"
fi

echo "MISTBORN_TAG=$MISTBORN_TAG" | sudo tee -a ${VAR_FILE}

#### SERVICE files

# copy current service files to systemd (overwriting as needed)
sudo cp /opt/mistborn/scripts/services/Mistborn* /etc/systemd/system/

# set script user and owner
sudo find /etc/systemd/system/ -type f -name 'Mistborn*' | xargs sudo sed -i "s/User=root/User=$USER/"
#sudo find /etc/systemd/system/ -type f -name 'Mistborn*' | xargs sudo sed -i "s/ root:root / $USER:$USER /"

# reload in case the iface is not immediately set
sudo systemctl daemon-reload

#### install and base services
iface=$(ip -o -4 route show to default | egrep -o 'dev [^ ]*' | awk 'NR==1{print $2}' | tr -d '[:space:]')
## cannot be empty
while [[ -z "$iface" ]]; do
    sleep 2
    iface=$(ip -o -4 route show to default | egrep -o 'dev [^ ]*' | awk 'NR==1{print $2}' | tr -d '[:space:]')
done

# default interface
sudo find /etc/systemd/system/ -type f -name 'Mistborn*' | xargs sudo sed -i "s/DIFACE/$iface/"

echo "DIFACE=${iface}" | sudo tee -a ${VAR_FILE}

sudo systemctl daemon-reload
