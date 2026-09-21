#!/bin/bash

# Объявляем цветной вывод (исправлено синтаксис)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

clear
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║              Настройка обхода блокировок Mihomo (Ручной ввод)               ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

echo -en "\n" ; echo "  # # Создание рабочих каталогов..."
sudo mkdir -p /usr/local/bin /etc/mihomo

if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    sudo curl -L -o /usr/local/bin/mihomo.gz https://github.com
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

echo -e "\n  ${yellow}[ИНСТРУКЦИЯ]${reset}"
echo "  1. Откройте в браузере сайт: https://github.io"
echo "  2. В блоке 'Clash' нажмите кнопку 'AWG 2.0' для скачивания конфига."
echo "  3. Откройте скачанный YAML-файл в текстовом редакторе."
echo -en "\n"

while [ -z "$USER_PRIVATE_KEY" ]; do
    read -p "  Вставьте значение private-key: " USER_PRIVATE_KEY
done

while [ -z "$USER_PUBLIC_KEY" ]; do
    read -p "  Вставьте значение public-key: " USER_PUBLIC_KEY
done

while [ -z "$USER_IP" ]; do
    read -p "  Вставьте значение ip (например, 172.16.0.2/32): " USER_IP
done

echo -e "\n  # # Сборка конфигурационного файла config.yaml..."
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

proxies:
  - name: "WARP"
    type: wireguard
    server: 162.159.192.1
    port: 2408
    ip: $USER_IP
    public-key: $USER_PUBLIC_KEY
    private-key: $USER_PRIVATE_KEY
    udp: true
    remote-dns-resolve: true
    keepalive: 25

proxy-groups:
  - name: WARP
    type: select
    proxies:
      - "WARP"

rules:
  - GEOIP,lan,DIRECT,no-resolve
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  - MATCH,WARP
EOF

echo "  # # Настройка фоновой службы туннеля (Systemd)..."
sudo tee /etc/systemd/system/mihomo.service > /dev/null << EOF
[Unit]
Description=Mihomo Cloudflare WARP Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

echo "  # # Запуск службы Mihomo. Ожидаем поднятия линка 5 секунд..."
sleep 5

if curl -m 5 -sI https://homebridge.io | grep -q "200"; then
    echo -e "\n  ${green}[УСПЕХ] Обход блокировок успешно настроен и запущен!${reset}"
    exit 0
else
    echo -e "\n  ${red}[ВНИМАНИЕ] Служба запущена, но тестовый пакет не прошел через WARP.${reset}"
    exit 1
fi
