#!/bin/bash

systemctl stop suricata
systemctl disable suricata

#kill $(pgrep -f suri_reloader) 2>/dev/null