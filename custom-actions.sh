#!/bin/bash

# FTP to Home Assistant
# Enable FTP server and a user with access to the the config share
# curl -T ./my-quake-shakes.ics ftp://HA.IP.ADD.RESS/config/www/ --user username:password

# Puts computer to sleep once the script has run - systemd hosts
# sleep 30s
# systemctl suspend