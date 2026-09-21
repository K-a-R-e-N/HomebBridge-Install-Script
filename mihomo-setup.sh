#!/bin/bash

# Настройка мягкой и контрастной цветовой палитры
cyan=$(tput setaf 6)
green=$(tput setaf 2)
amber=$(tput setaf 3)
dim=$(tput setaf 8)
reset=$(tput sgr0)

# Полностью вычищаем старые зависшие процессы AmneziaWG и Mihomo перед сборкой
sudo systemctl disable --now amneziawg > /dev/null 2>&1
sudo systemctl disable --now mihomo > /dev/null 2>&1
sudo killall -9 awg awg-quick mihomo > /dev/null 2>&1

echo "${cyan}╔═════════════════════════════════════════════════════════════════════════════╗${reset}"
echo "${cyan}║             Настройка обхода блокировок Mihomo (Вставка конфига)            ║${reset}"
echo "${cyan}╚═════════════════════════════════════════════════════════════════════════════╝${reset}"

# 1. Скрытое создание каталогов и скачивание ядра Mihomo строго по статье
sudo mkdir -p /usr/local/bin /etc/mihomo
if [ ! -f /usr/local/bin/mihomo ]; then
    sudo curl -sL -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 2. Грамотная пошаговая инструкция для пользователя
echo -e "\n  ${amber}ШАГ 1:${reset} Откройте в браузере сайт:"
echo -e "         ${green}https://warp-generation.github.io${reset}"
echo -e "\n  ${amber}ШАГ 2:${reset} Найдите блок ${cyan}Clash${reset} (фиолетовый кот справа) и нажмите"
echo -e "         оранжевую кнопку ${amber}AWG 2.0${reset} или ${amber}MASQUE${reset}, чтобы скачать файл."
echo -e "\n  ${amber}ШАГ 3:${reset} Откройте скачанный файл и полностью скопируйте"
echo -e "         весь его текст в буфер обмена (${cyan}Ctrl+A${reset}, затем ${cyan}Ctrl+C${reset})."
echo -e "\n  ${amber}ШАГ 4:${reset} Сейчас откроется редактор. Вставьте скопированный текст (${cyan}Ctrl+V${reset} или ${cyan}Shift+Insert${reset}),"
echo -e "         нажмите ${cyan}Ctrl+O${reset} -> ${cyan}Enter${reset} (сохранить) и ${cyan}Ctrl+X${reset} (выход)."
echo -en "\n"
read -p "  По готовности нажмите [ENTER], чтобы открыть редактор и вставить текст... "

# Открываем временный файл для ручной вставки оригинального текста статьи
sudo nano /etc/mihomo/user_warp.yaml

if [ ! -s /etc/mihomo/user_warp.yaml ]; then
    echo -e "\n  ${amber}Ошибка: Конфигурационный файл пустой. Действие отменено.${reset}\n"
    exit 1
fi

# 3. Автоматическая чистка вставленного файла от дублирующихся веток
sudo sed -i '/ipv6:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/allowed-ips:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/proxy-groups:/,$d' /etc/mihomo/user_warp.yaml
sudo sed -i '/rules:/,$d' /etc/mihomo/user_warp.yaml

# Подменяем порты, если провайдер заблокировал дефолтные 4500/2408
sudo sed -i 's/port: 4500/port: 3942/g' /etc/mihomo/user_warp.yaml
sudo sed -i 's/port: 2408/port: 8543/g' /etc/mihomo/user_warp.yaml

# 4. Сборка идеального config.yaml по архитектуре вашей статьи
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Полностью исключает вашу домашнюю сеть из VPN (Защита SSH/LAN)

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

EOF

# Приклеиваем блок с очищенными прокси
sudo cat /etc/mihomo/user_warp.yaml | sudo tee -a /etc/mihomo/config.yaml > /dev/null
sudo rm -f /etc/mihomo/user_warp.yaml

# Автоматически считываем имена всех прокси-серверов из файла
PROXY_NAMES=$(grep -- "- name:" /etc/mihomo/config.yaml | awk -F'"' '{print $2}')

# Дописываем прокси-группу, PersistentKeepalive и правила раздельного роутинга репозиториев
sudo tee -a /etc/mihomo/config.yaml > /dev/null << EOF

proxy-groups:
  - name: WARP
    type: fallback
    url: 'https://www.google.com/generate_204'
    interval: 150
    proxies:
$(echo "$PROXY_NAMES" | sed 's/^/      - "/;s/$/"/')

rules:
  # 1. Принудительно пускаем локальную сеть напрямую мимо VPN без DNS утечек
  - GEOIP,lan,DIRECT,no-resolve
  
  # 2. Список исключений для репозиториев Raspberry Pi, Debian и NodeSource (идут напрямую)
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  - DOMAIN-SUFFIX,nodesource.com,DIRECT
  
  # 3. Весь остальной внешний интернет-трафик (включая репозиторий Homebridge) заворачиваем в WARP
  - MATCH,WARP
EOF

# Принудительно пробиваем удержание сессии keepalive перед опциями Amnezia
sudo sed -i '/amnezia-wg-option:/i \    keepalive: 25' /etc/mihomo/config.yaml

# 5. Настройка автозапуска службы Systemd строго по коду юнита статьи
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

# Перезапуск менеджера systemd и запуск туннеля
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

# Ожидание поднятия линка
sleep 5

# 6. Контрольная проверка связи до репозитория Homebridge
if curl -m 6 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[ОК] Настройка обхода блокировок через Mihomo успешно завершена!${reset}\n"
    exit 0
else
    echo -e "\n  ${amber}[!] Служба запущена, но тестовый пакет не прошел через Mihomo-туннель.${reset}"
    echo -e "      ${dim}Посмотрите подробный лог ошибок: sudo journalctl -u mihomo -n 20${reset}\n"
    exit 1
fi
