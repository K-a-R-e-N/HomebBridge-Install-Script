#!/bin/bash

# Объявляем цветовые маркеры
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║             Настройка обхода блокировок Mihomo (Вставка конфига)            ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

echo -en "\n" ; echo "  # # Создание рабочих каталогов..."
sudo mkdir -p /usr/local/bin /etc/mihomo

# 1. Скачивание бинарного ядра Mihomo с GitHub
if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    sudo curl -L -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 2. Инструкция для вывода в терминал
echo -e "\n  ${yellow}┌────────────────────────── ИНСТРУКЦИЯ СКАЧИВАНИЯ ──────────────────────────┐${reset}"
echo "  │                                                                           │"
echo "  │  1. Перейдите по ссылке: https://warp-generation.github.io          │"
echo "  │                                                                           │"
echo "  │  2. Найдите блок с фиолетовым котом и надписью 'Clash' (справа)           │"
echo "  │                                                                           │"
echo "  │  3. Нажмите на оранжевую кнопку 'AWG 2.0' или 'MASQUE' внутри кота        │"
echo "  │                                                                           │"
echo "  │  4. Скопируйте ВЕСЬ открывшийся текст (от warp-common до MATCH,WARP)      │"
echo "  │                                                                           │"
echo "  │  5. Сейчас откроется nano. Вставьте текст, зажмите Ctrl+O -> Enter, Ctrl+X │"
echo "  │                                                                           │"
echo -e "  ${yellow}└───────────────────────────────────────────────────────────────────────────┘${reset}"
echo -en "\n"
read -p "  Вы прочитали инструкцию? Нажмите [ENTER] для открытия редактора..."

# Открываем временный файл для вставки скопированного буфера
sudo nano /etc/mihomo/user_warp.yaml

if [ ! -s /etc/mihomo/user_warp.yaml ]; then
    echo -e "  ${red}[ОШИБКА] Файл пустой! Вы ничего не вставили.${reset}"
    exit 1
fi

echo -e "\n  # # Оптимизация конфигурации, отключение IPv6 и защита LAN..."

# Чистим оригинальный файл от лишних сетевых маршрутов, ломающих локалку
sudo sed -i '/ipv6:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/allowed-ips:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/proxy-groups:/,$d' /etc/mihomo/user_warp.yaml
sudo sed -i '/rules:/,$d' /etc/mihomo/user_warp.yaml

# Собираем чистую и безопасную шапку config.yaml
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Изолируем домашнюю локальную сеть на уровне ядра (SSH/SprutHub)

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

EOF

# Соединяем чистую шапку с вашим AmneziaWG-блоком proxies
sudo cat /etc/mihomo/user_warp.yaml | sudo tee -a /etc/mihomo/config.yaml > /dev/null
sudo rm -f /etc/mihomo/user_warp.yaml

# Исправлено: добавлен ключ -- для защиты grep от дефиса в тексте "- name:"
PROXY_NAMES=$(grep -- "- name:" /etc/mihomo/config.yaml | awk -F'"' '{print $2}')

# Дописываем fallback-группу и финальные правила туннелирования со встроенным Keepalive
sudo tee -a /etc/mihomo/config.yaml > /dev/null << EOF

proxy-groups:
  - name: AMNEZIA_WARP
    type: fallback
    url: 'https://www.google.com/generate_204'
    interval: 150
    proxies:
$(echo "$PROXY_NAMES" | sed 's/^/      - "/;s/$/"/')

rules:
  # Запрещаем роутинг и DNS-опрос домашней сети через VPN-туннель
  - GEOIP,lan,DIRECT,no-resolve
  
  # Обновления пакетов Debian и Raspberry пускаем напрямую на максимальной скорости
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  
  # Заблокированные репозитории Homebridge отправляем в Amnezia-прокси
  - MATCH,AMNEZIA_WARP
EOF

# Добавляем параметр keepalive во все секции proxies для удержания NAT-сессии
sudo sed -i '/amnezia-wg-option:/i \    keepalive: 25' /etc/mihomo/config.yaml

# 3. Настройка системной фоновой службы юнита Systemd
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

# 4. Перезапуск systemd и запуск туннеля в операционной системе
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

echo "  # # Запуск службы Mihomo. Ожидаем поднятия линка 5 секунд..."
sleep 5

# 5. Итоговое тестирование соединения с репозиторием
if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[УСПЕХ] Обход блокировок AWG 2.0 MASQUE успешно настроен и запущен!${reset}"
    exit 0
else
    echo -e "\n  ${red}[ВНИМАНИЕ] Служба запущенна, но тестовый пакет не прошел через Amnezia-туннель.${reset}"
    echo "  Посмотрите подробный лог ошибок ядра: sudo journalctl -u mihomo -n 20"
    exit 1
fi
