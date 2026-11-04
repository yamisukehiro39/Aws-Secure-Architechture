#!/bin/bash
set -euo pipefail

install -d -m 0755 /opt/labshop
printf '%s' '${app_base64}' | base64 --decode > /opt/labshop/app.py
chmod 0644 /opt/labshop/app.py

cat > /etc/systemd/system/labshop.service <<'UNIT'
[Unit]
Description=LabShop API

[Service]
Type=simple
DynamicUser=yes
ExecStart=/usr/bin/python3 /opt/labshop/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable labshop.service
systemctl restart labshop.service

curl --fail --silent --show-error --max-time 3 \
  --retry 5 --retry-connrefused --retry-delay 1 \
  http://127.0.0.1:8081/health