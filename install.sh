#!/bin/bash

echo
echo =========================================
echo Установка Home Bridge и его зависимостей
echo =========================================
echo

echo Установка репозитория для Node.js 12.x...
curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -
echo Установка пакетов nodejs gcc g++ make python...
sudo apt-get install -y nodejs gcc g++ make python
echo Вывожу версии установленных пакетов:
echo Node && sudo node -v
echo Устранаем заранее известные проблемы...
sudo npm cache verify
echo Установка Home Bridge
sudo npm install -g --unsafe-perm homebridge
echo Установка интерфейса для Home Bridge...
sudo npm install -g --unsafe-perm homebridge-config-ui-x
echo Создаем основного пользователя для Home Bridge...
sudo useradd -m --system -G video homebridge
echo Добавляем полномочия интерфесу... 
sudo grep homebridge /etc/sudoers || echo 'homebridge    ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
echo Создаем основной каталог Home Bridge и даем права...
sudo mkdir -p /var/lib/homebridge
sudo chown -R homebridge: /var/lib/homebridge
echo Создаем конфигурационный файл Home Bridge...
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

echo Создаем сервис автозапуска...
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

echo Создаем файл основных настроек Home Bridge...
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

echo Запускаем фоново сервис homebridge
sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge

echo =============================================================
echo Процесс установки Home Bridge и его зависимостей, завершен !
echo =============================================================

echo Полезная информация для работы с Home Bridge
echo Логин и пароль:                admin/admin
echo Путь к файлу конфигурации:     /var/lib/homebridge/config.json
echo Путь хранения:                 /var/lib/homebridge
echo Перезагрузка Команды:          systemctl restart homebridge
echo Стоп Командная:                systemctl stop homebridge
echo Запустите команду:             systemctl start homebridge
echo Просмотр журналов Команда:     journalctl -f -n 100 -u homebridge
echo
echo Самоудаляем папку со скриптом установки...
cd ..	
sudo rm -rf HomebBridge-Install-Script
echo
