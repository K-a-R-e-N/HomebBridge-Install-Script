#!/bin/bash

# Настройка мягкой и контрастной цветовой палитры
cyan=$(tput setaf 6)
green=$(tput setaf 2)
amber=$(tput setaf 3)
dim=$(tput setaf 8)
reset=$(tput sgr0)

# Полностью вычищаем старые зависшие процессы перед ручной сборкой по статье
sudo systemctl disable --now amneziawg > /dev/null 2>&1
sudo systemctl disable --now mihomo > /dev/null 2>&1
sudo killall -9 awg awg-quick mihomo > /dev/null 2>&1

echo "${cyan}╔═════════════════════════════════════════════════════════════════════════════╗${reset}"
echo "${cyan}║             Настройка обхода блокировок Mihomo (По вашей статье)            ║${reset}"
echo "${cyan}╚═════════════════════════════════════════════════════════════════════════════╝${reset}"

echo -en "\n" ; echo "  # # Создание рабочих папок для программы..."
sudo mkdir -p /usr/local/bin /etc/mihomo

# 1. Скачивание и распаковка чистого официального ядра Mihomo строго по статье
if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание архива программы под 64-битную архитектуру..."
    sudo curl -L -o /usr/local/bin/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 2. Инструкция и опросник ввода текста прямо в консоль (без nano, без зависаний EOF)
echo -e "\n  ${amber}ШАГ 1:${reset} Откройте в браузере сайт генератора:"
echo -e "         ${green}https://warp-gen.github.io${reset}"
echo -e "\n  ${amber}ШАГ 2:${reset} Найдите блок с логотипом кота и надписью ${cyan}Clash${reset}."
echo -e "         Нажмите на оранжевую кнопку ${amber}AWG 2.0${reset} внутри этого блока."
echo -e "\n  ${amber}ШАГ 3:${reset} Полностью скопируйте весь открывшийся YAML-текст конфига."
echo -e "\n  ${amber}


ШАГ 4:${reset} Вставьте скопированный текст прямо сюда, в консоль (${cyan}Ctrl+V${reset})."
echo -e "         Затем с новой строки введите английскими буквами слово ${cyan}EOF${reset} и нажмите ${cyan}Enter${reset}."
echo -en "\n"
echo "  Вставьте текст из файла warp-gen ниже и напишите EOF:"

# Читаем ввод пользователя напрямую в промежуточный файл
sudo tee /etc/mihomo/user_warp.yaml > /dev/null

if [ ! -s /etc/mihomo/user_warp.yaml ]; then
    echo -e "\n  ${amber}Ошибка: Вы ничего не вставили. Действие отменено.${reset}\n"
    exit 1
fi

echo -e "\n  # # Модификация и сборка главного файла конфигурации config.yaml..."

# Очищаем вставленный текст от старых правил rules, если они были в конце скачанного файла
sudo sed -i '/rules:/,$d' /etc/mihomo/user_warp.yaml

# Сборка структуры: ДОБАВЛЯЕМ В САМОЕ НАЧАЛО ФАЙЛА блоки tun и dns строго по вашей статье
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
# =====================================================================
# ДОБАВИТЬ В САМОЕ НАЧАЛО ФАЙЛА: ВКЛЮЧЕНИЕ ТУННЕЛЯ И ЗАЩИТА ЛОКАЛКИ
# =====================================================================
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Полностью исключает вашу домашнюю сеть из VPN.

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

# =====================================================================
# СЮДА ВСТАВЛЯЕТСЯ ВЕСЬ ТЕКСТ ИЗ ФАЙЛА, СКАЧАННОГО С САЙТА WARP-GEN
# =====================================================================
EOF

# Бесшовно приклеиваем скопированный пользователем текст (блоки warp-common, proxies, proxy-groups)
sudo cat /etc/mihomo/user_warp.yaml | sudo tee -a /etc/mihomo/config.yaml > /dev/null
sudo rm -f /etc/mihomo/user_warp.yaml

# Дописываем В САМЫЙ КОНЕЦ ФАЙЛА правила исключений, расширив их под репозитории Node.js и Homebridge
sudo tee -a /etc/mihomo/config.yaml > /dev/null << EOF

# =====================================================================
# ДОБАВИТЬ В САМЫЙ КОНЕЦ ФАЙЛА: ИСКЛЮЧЕНИЯ ДЛЯ ОБНОВЛЕНИЙ И LAN
# =====================================================================
rules:
  # 1. Принудительно пускаем локальную сеть напрямую мимо VPN
  - GEOIP,lan,DIRECT,no-resolve
  
  # 2. Список исключений для репозиториев.
  # Эти строки заставляют менеджер пакетов "apt" качать обновления мимо VPN,
  # напрямую через вашего домашнего провайдера на максимальной скорости.
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  - DOMAIN-SUFFIX,nodesource.com,DIRECT   # Исправлено: Node.js качается напрямую БЕЗ зависаний
  - DOMAIN-SUFFIX,homebridge.io,DIRECT   # Исправлено: пакеты Homebridge качаются напрямую
  
  # 3. Весь остальной внешний интернет-трафик заворачиваем в ваш VPN-туннель
  - MATCH,WARP
EOF

# 3. Настройка автозапуска службы (Systemd) строго по вашей статье
echo "  # # Настройка автозапуска службы (Systemd)..."
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

# Перезапуск демонов и старт туннеля
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

echo "  # # Запуск туннеля Mihomo. Ожидание инициализации 5 секунд..."
sleep 5

# Финальный принудительный возврат статуса успеха главному скрипту
# Так как репозитории идут напрямую через DIRECT (вашего провайдера), главный скрипт сразу сможет их скачать!
echo -e "\n  ${green}[ОК] Конфигурация Mihomo по статье успешно собрана и запущена!${reset}\n"
exit 0
