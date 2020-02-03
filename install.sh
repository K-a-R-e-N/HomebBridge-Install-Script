#!/bin/bash

echo -en '\n'
echo '==============================================================='
echo '            Установка HomeBridge и его зависимостей'
echo '==============================================================='
echo -en '\n'
echo '# # Установка репозитория для Node.js 12.x...'
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -> /dev/null 2>&1
echo -en '\n'
echo '# # Установка пакетов nodejs gcc g++ make python...'
sudo apt-get install -y nodejs gcc g++ make python
echo -en '\n'
echo '# # Устраняем заранее известные проблемы...'
sudo npm cache verify > /dev/null 2>&1
echo -en '\n'
echo '# # Установка HomeBridge'
sudo npm install -g --unsafe-perm homebridge > /dev/null 2>&1
echo -en '\n'
echo '# # Установка интерфейса для HomeBridge...'
sudo npm install -g --unsafe-perm homebridge-config-ui-x > /dev/null 2>&1
echo -en '\n'
echo '# # Создаем основного пользователя для Home Bridge...'
sudo useradd -rm homebridge -G dialout,gpio,i2c
echo -en '\n'
echo '# # Добавляем полномочия интерфесу... '
sudo grep homebridge /etc/sudoers > /dev/null 2>&1 || echo 'homebridge    ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo > /dev/null 2>&1
echo -en '\n'
echo '# # Создаем основной каталог Home Bridge и даем права...'
[ ! -d ~/.homebridge ] && sudo mkdir -p ~/.homebridge
sudo chown -R homebridge: ~/.homebridge > /dev/null 2>&1
echo -en '\n'
echo '# # Создаем конфигурационный файл HomeBridge...'
sudo rm -rf ~/.homebridge/config.json
sudo tee -a ~/.homebridge/config.json > /dev/null 2>&1 <<_EOF_
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
            "platform": "config",
            "name": "Config",
            "port": 8080,
            "auth": "form",
            "standalone": true,
            "restart": "sudo -n systemctl restart homebridge homebridge-config-ui-x",
            "sudo": true,
            "log": {
                "method": "systemd",
                "service": "homebridge"
            }
        }
    ]
}
_EOF_

echo -en '\n'
echo '# # Создаем сервис автозапуска...'
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

echo -en '\n'
echo '# # Создаем сервис автозапуска Homebridge Config UI X для Standalone Mode...'

sudo rm -rf /etc/systemd/system/homebridge-config-ui-x.service
sudo tee -a /etc/systemd/system/homebridge-config-ui-x.service > /dev/null 2>&1 <<_EOF_
[Unit]
Description=Homebridge Config UI X
After=syslog.target network-online.target

[Service]
Type=simple
User=homebridge
EnvironmentFile=/etc/default/homebridge
ExecStart=$(which homebridge-config-ui-x) \$HOMEBRIDGE_OPTS
Restart=on-failure
RestartSec=3
KillMode=process
CapabilityBoundingSet=CAP_IPC_LOCK CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_CHOWN CAP_FOWNER CAP_DAC_OVERRIDE CAP_AUDIT_WRITE CAP_SYS_ADMIN
AmbientCapabilities=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
_EOF_

echo -en '\n'
echo '# # Создаем файл настроек HomeBridge...'
sudo rm -rf /etc/default/homebridge
sudo tee -a /etc/default/homebridge > /dev/null 2>&1 <<_EOF_
# Defaults / Configuration options for homebridge
# The following settings tells homebridge where to find the config.json file and where to persist the data (i.e. pairing and others)
HOMEBRIDGE_OPTS=-U $HOME/.homebridge -I

# If you uncomment the following line, homebridge will log more
# You can display this via systemd's journalctl: journalctl -f -u homebridge
# DEBUG=*

# To enable web terminals via homebridge-config-ui-x uncomment the following line
# HOMEBRIDGE_CONFIG_UI_TERMINAL=1
_EOF_

echo -en '\n'
echo '# # Запускаем сервис автоподгрузки'
sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge
sudo systemctl enable homebridge-config-ui-x
sudo systemctl start homebridge-config-ui-x
echo -en '\n'
echo '=============================================================='
echo ' Процесс установки Home Bridge и его зависимостей, завершен !'
echo '=============================================================='
echo -en '\n'
echo '     = Полезная информация для работы с Home Bridge ='
echo -en '\n'
echo '          Доступ по адресу: http://XXX.XXX.XXX.XXX:8080'
echo '            Логин и пароль: admin/admin'
echo -en '\n'
echo ' Путь к файлу конфигурации: sudo nano ~/.homebridge/config.json'
echo '             Путь хранения: cd ~/.homebridge/'
echo '      Перезагрузка Команды: sudo systemctl restart homebridge'
echo '            Стоп Командная: sudo systemctl stop homebridge'
echo '         Запустите команду: sudo systemctl start homebridge'
echo ' Просмотр журналов Команда: sudo journalctl -f -n 100 -u homebridge'
echo -en '\n'
echo -en '\n'
echo 'Самоудаляем папку со скриптом установки...'
cd ..	
sudo rm -rf HomebBridge-Install-Script
echo -en '\n'
