#!/bin/bash

# 1. Цветной вывод
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

clear
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║              Автоматическая настройка обхода блокировок Mihomo              ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# 2. Проверка существующего конфига (защита от лишней перезаписи аккаунта)
if [ -f /etc/mihomo/config.yaml ]; then
    echo -e "\n  ${yellow}[ИНФО] Конфигурация Mihomo уже создана ранее.${reset}"
    echo "  Перезапускаем и проверяем существующий туннель..."
    sudo systemctl restart mihomo > /dev/null 2>&1
    sleep 4
    if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
        echo -e "  ${green}[ОК] Старый туннель успешно запущен и работает!${reset}"
        exit 0
    fi
    echo "  [ИНФО] Старая сессия заблокирована. Перегенерируем профиль..."
fi

# 3. Создание системных директорий
echo -en "\n" ; echo "  # # Создание рабочих каталогов..."
sudo mkdir -p /usr/local/bin /etc/mihomo

# 4. Скачивание бинарного ядра Mihomo (Официальный GitHub)
if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    sudo curl -L -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 5. Автоматическая генерация профиля Cloudflare WARP в домашней папке пользователя
echo "  # # Генерация нового официального профиля Cloudflare WARP..."
WORK_DIR="/home/pi/warp_tmp"
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

curl -sSL https://raw.githubusercontent.com/ImMALWARE/bash-warp-generator/main/warp_generator.sh -o warp_generator.sh
chmod +x warp_generator.sh

# Запускаем генератор в домашней папке с гарантированными правами на исполнение
./warp_generator.sh > /dev/null 2>&1

# Извлекаем строго IPv4 параметры
WG_PRIVATE_KEY=$(grep "PrivateKey" wg0.conf 2>/dev/null | awk '{print $3}')
WG_ADDRESS_V4=$(grep "Address" wg0.conf 2>/dev/null | head -n 1 | awk '{print $3}' | cut -d',' -f1)
WG_PUBLIC_KEY=$(grep "PublicKey" wg0.conf 2>/dev/null | awk '{print $3}')
WG_ENDPOINT=$(grep "Endpoint" wg0.conf 2>/dev/null | awk '{print $3}')

# Чистим за собой временную рабочую папку
cd /home/pi && rm -rf "$WORK_DIR"

if [ -z "$WG_PRIVATE_KEY" ]; then
    echo -e "  ${red}[ОШИБКА] API Cloudflare отклонил запрос регистрации!${reset}"
    exit 1
fi

# 6. Сборка config.yaml (IPv6: Выкл, Keepalive: 25с, Раздельное туннелирование)
echo "  # # Сборка config.yaml (IPv6: Выкл, Keepalive: 25с, Раздельный туннель)..."
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Изолируем домашнюю локальную сеть на уровне ядра

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
    server: \$(echo \$WG_ENDPOINT | cut -d':' -f1)
    port: \$(echo \$WG_ENDPOINT | cut -d':' -f2)
    ip: \$WG_ADDRESS_V4
    public-key: \$WG_PUBLIC_KEY
    private-key: \$WG_PRIVATE_KEY
    udp: true
    remote-dns-resolve: true
    keepalive: 25      # Удержание сессии WireGuard за NAT роутера

proxy-groups:
  - name: WARP
    type: select
    proxies:
      - "WARP"

rules:
  # Локальная сеть идет строго напрямую без утечек внешних DNS-запросов
  - GEOIP,lan,DIRECT,no-resolve
  
  # Системные обновления Linux пускаем напрямую мимо VPN
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  
  # Заблокированный репозиторий Homebridge и все остальные внешние запросы заворачиваем в WARP
  - MATCH,WARP
EOF

# 7. Настройка юнита Systemd
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

# 8. Запуск туннеля
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

echo "  # # Запуск службы Mihomo. Ожидаем поднятия линка 5 секунд..."
sleep 5

# 9. Финальный тест сети
if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[УСПЕХ] Обход блокировок успешно настроен!${reset}"
    exit 0
else
    echo -e "\n  ${red}[ВНИМАНИЕ] Служба Mihomo запущена, но пакеты не проходят через WARP.${reset}"
    exit 1
fi
