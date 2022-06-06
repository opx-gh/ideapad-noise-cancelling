#!/usr/bin/env bash
ORIGIN_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

sudo systemctl stop ideapad-noise-cancelling.service
sudo systemctl disable ideapad-noise-cancelling.service

sudo rm /etc/ideapad-noise-cancelling.conf \
        /opt/ideapad-noise-cancelling.sh \
        /etc/systemd/system/ideapad-noise-cancelling.service
