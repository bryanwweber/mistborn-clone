#!/bin/bash

HASS_CONFIG="/opt/mistborn_volumes/extra/homeassistant/config/configuration.yaml"

if [[ -f "$HASS_CONFIG" ]]; then
    # configuration.yaml exists

    if [[ ! -z $(grep "use_x_forwarded_for: true" "$HASS_CONFIG") ]]; then
        # FOUND
        exit 0;
    fi

# add the proxy config
# write the trusted proxies config
cat >> ${HASS_CONFIG}<< EOF

http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12 

EOF

exit 0;

fi

# create parent directory if needed
PARENTDIR="$(dirname $HASS_CONFIG)"
if [[ ! -d "$PARENTDIR" ]]; then
    mkdir -p $PARENTDIR
fi

# write the trusted proxies config
cat >> ${HASS_CONFIG}<< EOF

# Configure a default setup of Home Assistant (frontend, api, etc)
default_config:

# Text to speech
#tts:
#  - platform: google_translate

#group: !include groups.yaml
#automation: !include automations.yaml
#script: !include scripts.yaml
#scene: !include scenes.yaml

http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12  

EOF
