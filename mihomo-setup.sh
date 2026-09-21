#!/bin/bash

# Объявляем цветной вывод
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

# 1. Скачивание ядра Mihomo
if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    sudo curl -L -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 2. Интерактивный запрос данных у пользователя (Исправлен адрес сайта)
echo -e "\n  ${yellow}[ИНСТРУКЦИЯ]${reset}"
echo "  1. Откройте в браузере правильный сайт: https://warp-generator.github.io"
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

# 3. Сборка конфигурационного файла config.yaml
echo -e "\n  # # Сборка конфигурационного файла config.yaml..."
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Полная защита вашей домашней локальной сети

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

proxies:
  - name: "WARP-1"
    type: wireguard
    server: 162.159.192.1
    port: 2408
    ip: $USER_IP
    public-key: $USER_PUBLIC_KEY
    private-key: $USER_PRIVATE_KEY
    udp: true
    remote-dns-resolve: true
    keepalive: 25

  - name: "WARP-2"
    type: wireguard
    server: 162.159.193.1
    port: 2408
    ip: $USER_IP
    public-key: $USER_PUBLIC_KEY
    private-key: $USER_PRIVATE_KEY
    udp: true
    remote-dns-resolve: true
    keepalive: 25

  - name: "WARP-3"
    type: wireguard
    server: 188.114.96.1
    port: 2408
    ip: $USER_IP
    public-key: $USER_PUBLIC_KEY
    private-key: $USER_PRIVATE_KEY
    udp: true
    remote-dns-resolve: true
    keepalive: 25

proxy-groups:
  - name: WARP
    type: fallback   # Автоматически переключит на рабочий IP, если первый заблокирован
    url: 'https://www.google.com/generate_204'
    interval: 300
    proxies:
      - "WARP-1"
      - "WARP-2"
      - "WARP-3"

rules:
  # Тотальное раздельное туннелирование: локалка идет строго напрямую
  - GEOIP,lan,DIRECT,no-resolve
  
  # Системные обновления Linux пускаем напрямую мимо VPN
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  
  # Всё остальное (включая заблокированный репозиторий Homebridge) заворачиваем в группу WARP
  - MATCH,WARP
EOF

# 4. Создание системной службы автозапуска (Systemd)
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

# 5. Запуск службы
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

echo "  # # Запуск службы Mihomo. Ожидаем поднятия линка 5 секунд..."
sleep 5

# 6. Финальное контрольное тестирование связи
if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[УСПЕХ] Обход блокировок успешно настроен и запущен!${reset}"
    exit 0
else
    echo -e "\n  ${red}[ВНИМАНИЕ] Служба запущенна, но тестовый пакет не прошел через WARP.${reset}"
    exit 1
fi
