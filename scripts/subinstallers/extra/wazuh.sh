#!/bin/bash

# Wazuh
WAZUH_PROD_FILE="$1"
echo "ELASTIC_USERNAME=mistborn" > $WAZUH_PROD_FILE
echo "ELASTIC_PASSWORD=$MISTBORN_DEFAULT_PASSWORD" >> $WAZUH_PROD_FILE

echo "ELASTICSEARCH_USERNAME=mistborn" >> $WAZUH_PROD_FILE
echo "ELASTICSEARCH_PASSWORD=$MISTBORN_DEFAULT_PASSWORD" >> $WAZUH_PROD_FILE

# kibana odfe
# kibana-odfe/config/wazuh_app_config.sh
# https://wazuh
echo "WAZUH_API_URL=https://10.2.3.1" >> $WAZUH_PROD_FILE
echo "API_PORT=55000" >> $WAZUH_PROD_FILE
echo "API_USERNAME=wazuh-wui" >> $WAZUH_PROD_FILE

#API_PASSWORD=$(python3 -c "import secrets; import string; print(f''.join([secrets.choice(string.ascii_letters+string.digits) for x in range(32)]))")

API_PASSWORD_PYTHON=$(cat << EOF

import secrets
import random
import string

random_pass = ([secrets.choice("@$!*?-"),
                           secrets.choice(string.digits),
                           secrets.choice(string.ascii_lowercase),
                           secrets.choice(string.ascii_uppercase),
                           ]
                          + [secrets.choice(string.ascii_lowercase
                                           + string.ascii_uppercase
                                           + "@$!*?-"
                                           + string.digits) for i in range(12)])

random.shuffle(random_pass)
random_pass = ''.join(random_pass)
print(random_pass)

EOF
)

API_PASSWORD=$(python3 -c "${API_PASSWORD_PYTHON}")

echo "API_PASSWORD=${API_PASSWORD}" >> $WAZUH_PROD_FILE

# kibana-odfe/config/entrypoint.sh:
# https://elasticsearch:9200
echo "ELASTICSEARCH_URL=https://10.2.3.1:9200" >> $WAZUH_PROD_FILE


cat >> ${WAZUH_PROD_FILE}<< EOF

PATTERN="wazuh-alerts-*"

CHECKS_PATTERN=true
CHECKS_TEMPLATE=true
CHECKS_API=true
CHECKS_SETUP=true

EXTENSIONS_PCI=true
EXTENSIONS_GDPR=true
EXTENSIONS_HIPAA=true
EXTENSIONS_NIST=true
EXTENSIONS_TSC=true
EXTENSIONS_AUDIT=true
EXTENSIONS_OSCAP=false
EXTENSIONS_CISCAT=false
EXTENSIONS_AWS=false
EXTENSIONS_GCP=false
EXTENSIONS_VIRUSTOTAL=true
EXTENSIONS_OSQUERY=true
EXTENSIONS_DOCKER=true

APP_TIMEOUT=20000

API_SELECTOR=true
IP_SELECTOR=true
IP_IGNORE="[]"

WAZUH_MONITORING_ENABLED=true
WAZUH_MONITORING_FREQUENCY=900
WAZUH_MONITORING_SHARDS=2
WAZUH_MONITORING_REPLICAS=0

ADMIN_PRIVILEGES=true

EOF

echo "MISTBORN_DEFAULT_PASSWORD=$MISTBORN_DEFAULT_PASSWORD" >> $WAZUH_PROD_FILE

chmod 600 $WAZUH_PROD_FILE
