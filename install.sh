#!/bin/bash

echo
echo =========================================
echo Установка Home Bridge и его зависимостей
echo =========================================
echo

curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -
sudo apt-get install -y nodejs gcc g++ make python && node -v
sudo npm cache verify
sudo npm install -g --unsafe-perm homebridge
sudo npm install -g --unsafe-perm homebridge-config-ui-x
sudo useradd -m --system -G video homebridge
sudo grep homebridge /etc/sudoers || echo 'homebridge    ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
sudo mkdir -p /var/lib/homebridge

sudo rm -rf /var/lib/homebridge/config.json
sudo tee -a /var/lib/homebridge/config.json > /dev/null 2>&1 <<_EOF_
{
    "bridge": {
        "name": "Homebridge",
        "username": "CB:22:3D:E2:CE:31",
        "port": 51826,
        "pin": "033-44-254"
    },
    "accessories": [],
    "platforms": [
        {
            "name": "Config",
            "port": 8080,
            "auth": "form",
            "restart": "sudo -n systemctl restart homebridge",
            "sudo": true,
            "log": {
                "method": "systemd"
            },
            "platform": "config"
        }
    ]
}
_EOF_

sudo rm -rf /etc/systemd/system/homebridge.service
sudo tee -a /etc/systemd/system/homebridge.service > /dev/null 2>&1 <<_EOF_
[Unit]
Description=Homebridge
After=syslog.target network-online.target

[Service]
Type=simple
User=homebridge
EnvironmentFile=/etc/default/homebridge
ExecStart=$(which homebridge) \$HOMEBRIDGE_OPTS
Restart=on-failure
RestartSec=3
KillMode=process
CapabilityBoundingSet=CAP_IPC_LOCK CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_CHOWN CAP_FOWNER CAP_DAC_OVERRIDE CAP_AUDIT_WRITE CAP_SYS_ADMIN
AmbientCapabilities=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
_EOF_

sudo rm -rf /etc/default/homebridge
sudo tee -a /etc/default/homebridge > /dev/null 2>&1 <<_EOF_
# Defaults / Configuration options for homebridge
# The following settings tells homebridge where to find the config.json file and where to persist the data (i.e. pairing and others)
HOMEBRIDGE_OPTS=-U /var/lib/homebridge -I

# If you uncomment the following line, homebridge will log more
# You can display this via systemd's journalctl: journalctl -f -u homebridge
# DEBUG=*

# To enable web terminals via homebridge-config-ui-x uncomment the following line
# HOMEBRIDGE_CONFIG_UI_TERMINAL=1
_EOF_

sudo chown -R homebridge: /var/lib/homebridge
sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge

echo =============================================================
echo Процесс установки Home Bridge и его зависимостей, завершен !
echo =============================================================
echo
echo Самоудаляемся...
cd ..	
sudo rm -rf HomebBridge-Install-Script
echo
