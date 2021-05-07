#!/bin/bash

set -e

# detect if suricata is installed
if [[ $(dpkg-query -W -f='${Status}' suricata 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
    echo "Suricata Installed"
    exit 0
fi

source /opt/mistborn/scripts/subinstallers/platform.sh

# minimal dependencies
sudo -E apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev build-essential libpcap-dev   \
                libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev \
                make libmagic-dev libjansson-dev jq wget

## recommended dependencies
#sudo -E apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev build-essential libpcap-dev   \
#                libnet1-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev \
#                libcap-ng-dev libcap-ng0 make libmagic-dev         \
#                libgeoip-dev liblua5.1-dev libhiredis-dev libevent-dev \
#                python-yaml rustc cargo

# iptables/nftables integration
sudo -E apt-get -y install libnetfilter-queue-dev libnetfilter-queue1  \
                libnetfilter-log-dev libnetfilter-log1      \
                libnfnetlink-dev libnfnetlink0


if [ "$DISTRO" == "ubuntu" ]; then
    echo "Installing Suricata Ubuntu PPA"
    sudo -E add-apt-repository -y ppa:oisf/suricata-stable
    sudo -E apt-get update
    sudo -E apt-get install -y suricata
elif [ "$DISTRO" == "debian" ]; then
    # retrieve version codename
    source /etc/os-release
    echo "deb http://http.debian.net/debian $VERSION_CODENAME-backports main" | \
        sudo -E tee /etc/apt/sources.list.d/backports.list
    sudo -E apt-get update
    sudo -E apt-get install -y suricata -t ${VERSION_CODENAME}-backports
else
    echo "Basic Suricata installation"
    sudo -E apt-get install -y suricata
fi

# # iptables
# sudo iptables -A INPUT -j NFQUEUE
# sudo iptables -I FORWARD -j NFQUEUE
# sudo iptables -I OUTPUT -j NFQUEUE

# # rsyslog to create /var/log/suricata.log
# sudo cp ./scripts/conf/20-suricata.conf /etc/rsyslog.d/
# sudo chown root:root /etc/rsyslog.d/20-suricata.conf
# sudo systemctl restart rsyslog

# rules
pushd .
cd /tmp
wget https://rules.emergingthreats.net/open/suricata-4.0/emerging.rules.tar.gz
tar zxvf emerging.rules.tar.gz
sudo -E rm /etc/suricata/rules/* -f
sudo -E mv rules/*.rules /etc/suricata/rules/
popd

# suricata yaml
sudo -E rm -f /etc/suricata/suricata.yaml
sudo -E wget -O /etc/suricata/suricata.yaml http://www.branchnetconsulting.com/wazuh/suricata.yaml

IFACE=$(ip -o -4 route show to default | awk 'NR==1{print $5}')
sudo sed -i "s/eth0/${IFACE}/g" /etc/suricata/suricata.yaml
sudo sed -i "s/eth0/${IFACE}/g" /etc/default/suricata

#systemctl restart suricata

# wait for service to be listening
while ! nc -z 10.2.3.1 55000; do
    WAIT_TIME=10
    echo "Waiting ${WAIT_TIME} seconds for Wazuh API..."
    sleep ${WAIT_TIME}
done

# set working directory to mistborn for docker-compose
pushd .
cd /opt/mistborn

# ensure group exists
sudo docker-compose --env-file /opt/mistborn/.env -f extra/wazuh.yml exec -T wazuh /var/ossec/bin/agent_groups -a -g suricata -q 2>/dev/null

# add this host to group
WAZUH_ID=$(sudo docker-compose --env-file /opt/mistborn/.env -f extra/wazuh.yml exec -T wazuh /var/ossec/bin/manage_agents -l | egrep ^\ *ID | grep $(hostname) | awk '{print $2}' | tr -d ',')
sudo docker-compose --env-file /opt/mistborn/.env -f extra/wazuh.yml exec -T wazuh /var/ossec/bin/agent_groups -a -i ${WAZUH_ID} -g suricata -q

# write agent.conf
sudo docker-compose --env-file /opt/mistborn/.env -f extra/wazuh.yml exec -T wazuh bash -c "cat > /var/ossec/etc/shared/suricata/agent.conf << EOF
<agent_config>
    <localfile>
        <log_format>json</log_format>
        <location>/var/log/suricata/eve.json</location>
    </localfile>
</agent_config>
EOF
"

# restart manager
sudo docker-compose --env-file /opt/mistborn/.env -f extra/wazuh.yml restart wazuh

popd

# suricata-update
sudo -E apt install python3-pip
sudo -E pip3 install pyyaml
sudo -E pip3 install https://github.com/OISF/suricata-update/archive/master.zip

sudo -E pip3 install --pre --upgrade suricata-update

# sudo -E suricata-update enable-source oisf/trafficid
# sudo -E suricata-update enable-source etnetera/aggressive
# sudo -E suricata-update enable-source sslbl/ssl-fp-blacklist
# sudo -E suricata-update enable-source et/open
# sudo -E suricata-update enable-source tgreen/hunting
# sudo -E suricata-update enable-source sslbl/ja3-fingerprints
# sudo -E suricata-update enable-source ptresearch/attackdetection

sudo -E suricata-update

sudo systemctl daemon-reload
sudo systemctl restart suricata