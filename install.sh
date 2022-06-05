#!/usr/bin/env bash
ORIGIN_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

sudo cp "${ORIGIN_DIR}/ideapad-noise-cancelling.conf" /etc/
sudo cp "${ORIGIN_DIR}/ideapad-noise-cancelling.sh" /opt/
sudo cp "${ORIGIN_DIR}/ideapad-noise-cancelling.service" /etc/systemd/system/

sudo systemctl enable ideapad-noise-cancelling.service
sudo systemctl start ideapad-noise-cancelling.service
