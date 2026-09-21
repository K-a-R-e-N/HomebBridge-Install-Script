#!/bin/bash

# Настройка мягкой и контрастной цветовой палитры
cyan=$(tput setaf 6)
green=$(tput setaf 2)
amber=$(tput setaf 3)
dim=$(tput setaf 8)
reset=$(tput sgr0)

# 1. Скрытое создание каталогов и скачивание ядра Mihomo с GitHub
sudo mkdir -p /usr/local/bin /etc/mihomo
if [ ! -f /usr/local/bin/mihomo ]; then
    sudo curl -sL -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

clear
echo "${cyan}╔═════════════════════════════════════════════════════════════════════════════╗${reset}"
echo "${cyan}║             Настройка обхода блокировок Mihomo (Вставка конфига)            ║${reset}"
echo "${cyan}╚═════════════════════════════════════════════════════════════════════════════╝${reset}"

# 2. Грамотная и чистая пошаговая инструкция для пользователя
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

# Открываем временный файл в тихом режиме для вставки оригинального буфера
sudo nano /etc/mihomo/user_warp.yaml

if [ ! -s /etc/mihomo/user_warp.yaml ]; then
    echo -e "\n  ${amber}Ошибка: Конфигурационный файл пустой. Действие отменено.${reset}\n"
    exit 1
fi

# 3. Автоматическая оптимизация, вырезание IPv6 и внедрение защиты локальной сети
sudo sed -i '/ipv6:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/allowed-ips:/d' /etc/mihomo/user_warp.yaml
sudo sed -i '/proxy-groups:/,$d' /etc/mihomo/user_warp.yaml
sudo sed -i '/rules:/,$d' /etc/mihomo/user_warp.yaml

# Умный обход: если порты стандартные (4500 или 2408), принудительно меняем их на рабочие нестандартные
sudo sed -i 's/port: 4500/port: 3248/g' /etc/mihomo/user_warp.yaml
sudo sed -i 's/port: 2408/port: 8431/g' /etc/mihomo/user_warp.yaml

# Сборка чистой и безопасной системной шапки туннеля
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Полная изоляция вашей домашней локальной сети (SSH/SprutHub)

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

EOF

# Бесшовное объединение шапки с AmneziaWG-блоком proxies пользователя
sudo cat /etc/mihomo/user_warp.yaml | sudo tee -a /etc/mihomo/config.yaml > /dev/null
sudo rm -f /etc/mihomo/user_warp.yaml

# Динамический сбор имен всех сгенерированных серверов
PROXY_NAMES=$(grep -- "- name:" /etc/mihomo/config.yaml | awk -F'"' '{print $2}')

# Дозапись отказоустойчивой proxy-группы и жёстких правил раздельного маршрута
sudo tee -a /etc/mihomo/config.yaml > /dev/null << EOF

proxy-groups:
  - name: AMNEZIA_WARP
    type: fallback
    url: 'https://www.google.com/generate_204'
    interval: 150
    proxies:
$(echo "$PROXY_NAMES" | sed 's/^/      - "/;s/$/"/')

rules:
  # Домашняя сеть и SSH идут строго напрямую мимо туннеля без утечек внешних DNS-запросов
  - GEOIP,lan,DIRECT,no-resolve
  
  # Пакеты обновлений операционной системы Linux качаем на максимальной скорости провайдера
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  
  # Трафик к заблокированному репозиторию Homebridge принудительно уводим в Amnezia-прокси
  - MATCH,AMNEZIA_WARP
EOF

# Автоматическое внедрение тайм-аута удержания NAT-сессии WireGuard перед блоком опций Amnezia
sudo sed -i '/amnezia-wg-option:/i \    keepalive: 25' /etc/mihomo/config.yaml

# 4. Скрытое создание системного юнита Systemd для фонового автозапуска туннеля
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

# Активация и запуск фоновой службы в ОС
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

# Ожидание инициализации и поднятия сетевого линка с Cloudflare
sleep 6

# 5. Итоговое контрольное тестирование линка до заблокированного сервера
if curl -m 6 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[ОК] Настройка обхода блокировок успешно завершена!${reset}\n"
    exit 0
else
    echo -e "\n  ${amber}[!] Служба запущена, но соединение через Amnezia-туннель отсутствует.${reset}"
    echo -e "      ${dim}Проверьте логи ядра: sudo journalctl -u mihomo -n 20${reset}\n"
    exit 1
fi
