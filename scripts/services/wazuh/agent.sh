#!/bin/bash

# detect if already installed
if dpkg -s wazuh-agent &> /dev/null; then
    echo "Wazuh agent already installed"
    exit 0
fi

# install curl
echo "install curl"
sudo -E apt-get install -y curl

# prepare repo
echo "Adding Wazuh Repository"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo -E apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo -E tee /etc/apt/sources.list.d/wazuh.list

apt-get update

# wait for service to be listening
while ! nc -z 10.2.3.1 55000; do
    WAIT_TIME=10
    echo "Waiting ${WAIT_TIME} seconds for Wazuh API..."
    sleep ${WAIT_TIME}
done

# install
echo "Installing Wazuh agent"
WAZUH_MANAGER="10.2.3.1" apt-get install wazuh-agent

