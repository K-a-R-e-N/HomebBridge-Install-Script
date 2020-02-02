#!/bin/bash

echo ==========================================
echo  Установка Home Bridge и его зависимостей
echo ==========================================

sudo su
sudo curl -sL https://deb.nodesource.com/setup_12.x | bash -
sudo apt-get install -y nodejs gcc g++ make python && node -v
npm cache verify
npm install -g --unsafe-perm homebridge
npm install -g --unsafe-perm homebridge-config-ui-x
useradd -m --system -G video homebridge
grep homebridge /etc/sudoers || echo 'homebridge    ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
mkdir -p /var/lib/homebridge
rm -rf /var/lib/homebridge/config.json
tee -a /var/lib/homebridge/config.json <<_EOF_
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
rm -rf /etc/systemd/system/homebridge.service
tee -a /etc/systemd/system/homebridge.service <<_EOF_
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
rm -rf /etc/default/homebridge
tee -a /etc/default/homebridge <<_EOF_
# Defaults / Configuration options for homebridge
# The following settings tells homebridge where to find the config.json file and where to persist the data (i.e. pairing and others)
HOMEBRIDGE_OPTS=-U /var/lib/homebridge -I

# If you uncomment the following line, homebridge will log more
# You can display this via systemd's journalctl: journalctl -f -u homebridge
# DEBUG=*

# To enable web terminals via homebridge-config-ui-x uncomment the following line
# HOMEBRIDGE_CONFIG_UI_TERMINAL=1
_EOF_
chown -R homebridge: /var/lib/homebridge
exit

sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge

echo ==============================================================
echo  Процесс установки Home Bridge и его зависимостей, завершен !
echo ==============================================================
echo Самоудаляемся...
sudo rm -rf /home/pi/HomebBridge-Install-Script/
