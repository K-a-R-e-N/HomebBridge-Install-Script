#!/bin/bash


function Zagolovok {
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                   Установка HomeBridge и его зависимостей                   ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
}
function GoToMenu {
  while :
  do
  echo "        ┌─ Выберите действие: ────────────────────────────────────────┐"
  echo "        │                                                             │"
  echo "        │    1 - Завершить работу скрипта                             │"
  echo "        │    2 - Предварительно очистить систему                      │"
  echo "        │    3 - Продолжить без очистки системы (Для опытных)         │"
  echo "        │                                                             │"
  echo "        │  Чтобы продолжить, введите номер пункта и нажмите на Enter  │"
  echo "        │                                                             │"
  echo "        └─────────────────────────────────────────────────────────────┘"
  echo "                           Ввведите номер пункта:"
  read a
  printf "\n"
  case $a in
  1)     echo "     - Завершить работу скрипта..." && exit 0;;
  2)     echo "     - Предварительно очистить систему..." && bash uninstall.sh && return;;
  3)     echo "     - Продолжить без очистки системы..." && if [ -f ~/.homebridge/config.json ]; then; echo -en "\n" ; echo "# # Создание резервной копии конфигурационного файла HomeBridge..." && sudo cp -f ~/.homebridge/config.json ~/.config.json.$(date +%s)000; fi; return;;
  *)     echo "                           Попробуйте еще раз.";;
  esac
  done
  Zagolovok
}
Zagolovok

echo -en "\n" ; echo "# # Проверка на ранее установленную версию..."
if dpkg -l homebridge &>/dev/null; then
  echo "     - В вашей системе уже установлен HomeBridge как системный пакет..."
  GoToMenu
elif dpkg -l nodejs &>/dev/null; then
  if npm list -g | grep -q homebridge; then
  echo "     - В вашей системе уже установлен HomeBridge из NPM..."
  GoToMenu
  else
  echo "     - В системе уже установлен пакет NodeJS $(nodejs -v), но HomeBridge не установлен..."
  GoToMenu
  fi
else
  echo "     - Ранее установленых пакетов не обнаружено..."
fi

echo -en "\n" ; echo "# # Установка Node.js..."
echo "     - Добавление ключа подписи пакета NodeSource..."
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key --quiet add -
echo "     - Добавление репозитория NodeSource..."
NODE_VERSION=node_12.x && DISTRO="$(lsb_release -s -c)"
echo "deb https://deb.nodesource.com/$NODE_VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "deb-src https://deb.nodesource.com/$NODE_VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "     - Обновление списка пакетов и установка Node.js..."
sudo apt-get update > /dev/null && sudo apt-get install -y nodejs > /dev/null

echo -en "\n" ; echo "# # Установка пакетов gcc g++ make python..."
sudo apt-get install -y gcc g++ make python > /dev/null

echo -en "\n" ; echo "# # Установка пакета libavahi-compat-libdnssd-dev..."
sudo apt-get install -y libavahi-compat-libdnssd-dev > /dev/null

echo -en "\n" ; echo "# # Устранение ранее известных проблем..."
sudo npm cache verify > /dev/null

echo -en "\n" ; echo "# # Установка HomeBridge..."
sudo npm install -g --unsafe-perm homebridge > /dev/null

echo -en "\n" ; echo "# # Установка интерфейса для HomeBridge..."
sudo npm install -g --unsafe-perm homebridge-config-ui-x > /dev/null

echo -en "\n" ; echo "# # Создание основного пользователя для HomeBridge..."
sudo useradd -rm homebridge -G dialout,gpio,i2c > /dev/null

echo -en "\n" ; echo "# # Добавление полномочия по управлению через интерфейс..."
sudo grep homebridge /etc/sudoers > /dev/null || echo 'homebridge    ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo > /dev/null

echo -en "\n" ; echo "# # Создание основного каталога HomeBridge..."
[ ! -d ~/.homebridge ] && sudo mkdir -p ~/.homebridge
sudo chown -R homebridge: ~/.homebridge > /dev/null

echo -en "\n" ; echo "# # Создание конфигурационного файла HomeBridge..."
sudo rm -rf ~/.homebridge/config.json
sudo tee -a ~/.homebridge/config.json > /dev/null <<_EOF_
{
    "bridge": {
        "name": "Homebridge",
        "username": "CB:22:3D:E2:CE:31",
        "port": 51826,
        "pin": "432-11-234"
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

echo -en "\n" ; echo "# # Создание служб автозапуска..."
sudo rm -rf /etc/systemd/system/homebridge.service
sudo tee -a /etc/systemd/system/homebridge.service > /dev/null <<_EOF_
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

sudo rm -rf /etc/systemd/system/homebridge-config-ui-x.service
sudo tee -a /etc/systemd/system/homebridge-config-ui-x.service > /dev/null <<_EOF_
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

echo -en "\n" ; echo "# # Создаем файл настроек HomeBridge..."
sudo rm -rf /etc/default/homebridge
sudo tee -a /etc/default/homebridge > /dev/null <<_EOF_
# Defaults / Configuration options for homebridge
# The following settings tells homebridge where to find the config.json file and where to persist the data (i.e. pairing and others)
HOMEBRIDGE_OPTS=-U $HOME/.homebridge -I

# If you uncomment the following line, homebridge will log more
# You can display this via systemd's journalctl: journalctl -f -u homebridge
# DEBUG=*

# To enable web terminals via homebridge-config-ui-x uncomment the following line
# HOMEBRIDGE_CONFIG_UI_TERMINAL=1
_EOF_

if [ -f /home/pi/config.json.* ]; then 
echo -en "\n" ; echo "# # Восстанавливаем резервную копию конфигурационного файла HomeBridge..."
sudo mv -f /home/pi/config.json.* ~/.homebridge/
fi

echo -en "\n" ; echo "# # Добавление служб в список автозагрузки и их запуск..."
sudo systemctl -q daemon-reload
sudo systemctl -q enable homebridge
sudo systemctl -q start homebridge
sudo systemctl -q enable homebridge-config-ui-x
sudo systemctl -q start homebridge-config-ui-x


echo -en "\n"
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║          Процесс установки HomeBridge и его зависимостей завершена          ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
echo "    ┌──────────── Полезная информация для работы с HomeBridge ────────────┐"
echo "    │                                                                     │"
echo "    │                    Доступ к HomeBridge по адресу                    │"
echo "    │                      http://$(hostname -I | tr -d ' '):8080/                      │"
echo "    │                                                                     │"
echo "    │                       Логин и пароль для входа                      │"
echo "    │                            admin / admin                            │"
echo "    │                                                                     │"
echo "    │                  Редактирование файла конфигурации                  │"
echo "    │                 sudo nano ~/.homebridge/config.json                 │"
echo "    │                                                                     │"
echo "    │                     Перезагрузка Home Assistant                     │"
echo "    │                  sudo systemctl restart homebridge                  │"
echo "    │                                                                     │"
echo "    │                          Просмотр журналов                          │"
echo "    │               sudo journalctl -f -n 100 -u homebridge               │"
echo "    │                                                                     │"
echo "    └─────────────────────────────────────────────────────────────────────┘"
echo -en "\n"
