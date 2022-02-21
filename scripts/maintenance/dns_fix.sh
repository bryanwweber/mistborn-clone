#!/bin/bash

set -e

# stop Mistborn-base
sudo systemctl stop Mistborn-base

# get DNS server
read -p "(Mistborn) Set DNS server: [1.1.1.1] " DNS_IP
DNS_IP=${DNS_IP:-1.1.1.1}

# set external nameserver
echo "nameserver ${DNS_IP}" | sudo tee /etc/resolv.conf

# save OUTPUT rules
FW_FILE="$(mktemp)"

sudo rm -f ${FW_FILE} || true

echo "*filter" | tee ${FW_FILE}
sudo iptables-save | grep -E " OUTPUT " | tee -a ${FW_FILE}
echo "COMMIT" | tee -a ${FW_FILE}

# flush
sudo iptables -F OUTPUT

# bring up temporary DNS
sudo systemctl restart systemd-resolved

# pull images
sudo docker-compose -f /opt/mistborn/base.yml --env-file /opt/mistborn/.env pull
sudo docker-compose -f /opt/mistborn/base.yml --env-file /opt/mistborn/.env build

# stop temporary DNS
sudo systemctl stop systemd-resolved

# restore firewall rules
sudo iptables-restore -n < ${FW_FILE}

# restart Mistborn
sudo systemctl restart Mistborn-base