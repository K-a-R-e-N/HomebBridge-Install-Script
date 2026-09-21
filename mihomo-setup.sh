#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

clear
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║             Настройка обхода блокировок Mihomo (Вставка конфига)            ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

echo -en "\n" ; echo "  # # Создание рабочих каталогов..."
sudo mkdir -p /usr/local/bin /etc/mihomo

if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    sudo curl -L -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

echo -e "\n  ${yellow}[ИНСТРУКЦИЯ]${reset}"
echo "  1. Сейчас откроется пустой текстовый редактор."
echo "  2. Вставьте скопированный текст файла с сайта warp-generation.github.io"
echo "  3. Нажмите Ctrl+O, затем Enter (сохранить) и Ctrl+X (выйти)."
echo -en "\n"
read -p "  Нажмите [ENTER], чтобы открыть редактор и вставить текст..."

sudo nano /etc/mihomo/user_warp.yaml

if [ ! -s /etc/mihomo/user_warp.yaml ]; then
    echo -e "  ${red}[ОШИБКА] Файл пустой! Вы ничего не вставили.${reset}"
    exit 1
fi

echo -e "\n  # # Оптимизация конфигурации, отключение IPv6 и защита LAN..."

# Вырезаем нестабильный IPv6 и лишние блоки
sudo sed -i '/ipv6:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/allowed-ips:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/proxy-groups:/,$d' /etc/mihomo/user_warp.yaml
sudo sed -i '/rules:/,$d' /etc/mihomo/user_warp.yaml

# Создаем правильную и безопасную шапку конфигурации
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Защита локальной домашней сети (SSH/SprutHub)

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

EOF

# Приклеиваем блок с прокси-серверами из файла пользователя
sudo cat /etc/mihomo/user_warp.yaml | sudo tee -a /etc/mihomo/config.yaml > /dev/null
sudo rm -f /etc/mihomo/user_warp.yaml

# Автоматически вытаскиваем имена всех добавленных прокси-серверов для создания правильной группы управления
PROXY_NAMES=$(grep "- name:" /etc/mihomo/config.yaml | awk -F'"' '{print $2}')

# Дописываем динамическую прокси-группу и финальные жесткие правила раздельного туннелирования
sudo tee -a /etc/mihomo/config.yaml > /dev/null << EOF

proxy-groups:
  - name: AMNEZIA_WARP
    type: fallback
    url: 'https://www.google.com/generate_204'
    interval: 150
    proxies:
$(echo "$PROXY_NAMES" | sed 's/^/      - "/;s/$/"/')

rules:
  # Локальная домашняя сеть идет строго напрямую мимо туннеля
  - GEOIP,lan,DIRECT,no-resolve
  
  # Системные обновления пакетов OS качаем на максимальной скорости провайдера напрямую
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  
  # Весь трафик к заблокированному репозиторию Homebridge пускаем через Amnezia-туннель
  - MATCH,AMNEZIA_WARP
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

if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[УСПЕХ] Обход блокировок AWG 2.0 MASQUE успешно настроен и запущен!${reset}"
    exit 0
else
    echo -e "\n  ${red}[ВНИМАНИЕ] Служба запущенна, но тестовый пакет не прошел через Amnezia-туннель.${reset}"
    echo "  Посмотрите подробный лог ошибок ядра: sudo journalctl -u mihomo -n 20"
    exit 1
fi
