#!/bin/bash

# Объявляем цвета
red=\$(tput setaf 1)
green=\$(tput setaf 2)
yellow=\$(tput setaf 3)
reset=\$(tput sgr0)

clear
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║             Настройка обхода блокировок Mihomo (Вставка конфига)            ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

echo -en "\n" ; echo "  # # Создание рабочих каталогов..."
sudo mkdir -p /usr/local/bin /etc/mihomo

# 1. Скачивание ядра Mihomo
if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    sudo curl -L -o /usr/local/bin/mihomo[ТОЧКА]gz https://github[ТОЧКА]com/MetaCubeX/mihomo/releases/download/v1[ТОЧКА]19[ТОЧКА]30/mihomo-linux-arm64-v1[ТОЧКА]19[ТОЧКА]30[ТОЧКА]gz
    sudo gunzip -f /usr/local/bin/mihomo[ТОЧКА]gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 2. Пауза для ручной вставки скопированного файла
echo -e "\n  \${yellow}[ИНСТРУКЦИЯ]\${reset}"
echo "  1. Сейчас откроется пустой текстовый редактор."
echo "  2. Скопируйте ВЕСЬ текст скачанного файла с сайта warp-generation[ТОЧКА]github[ТОЧКА]io"
echo "  3. Вставьте его в редактор, нажмите Ctrl+O -> Enter (сохранить) и Ctrl+X (выйти)."
echo -en "\n"
read -p "  Нажмите [ENTER], чтобы открыть редактор и вставить текст..."

# Открываем временный файл для вставки оригинального конфига
sudo nano /etc/mihomo/user_warp[ТОЧКА]yaml

if [ ! -s /etc/mihomo/user_warp[ТОЧКА]yaml ]; then
    echo -e "  \${red}[ОШИБКА] Файл пустой! Вы ничего не вставили.\${reset}"
    exit 1
fi

# 3. Автоматическая очистка, вырезание IPv6 и внедрение правил защиты локальной сети
echo -e "\n  # # Оптимизация конфигурации, отключение IPv6 и защита LAN..."

# Вырезаем строки с ipv6, allowed-ips (Mihomo сам маршрутизирует трафик) и дефолтные правила rules
sudo sed -i '/ipv6:/d' /etc/mihomo/user_warp[ТОЧКА]yaml
sudo sed -i '/allowed-ips:/d' /etc/mihomo/user_warp[ТОЧКА]yaml
sudo sed -i '/rules:/,\$d' /etc/mihomo/user_warp[ТОЧКА]yaml

# Собираем финальный config[ТОЧКА]yaml с правильной структурой туннеля и разделением трафика
sudo tee /etc/mihomo/config[ТОЧКА]yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Тотальная защита вашей домашней локальной сети (SSH/SprutHub)

dns:
  enable: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:53
  nameserver:
    - 1.1.1.1
    - 8.8.8.8

EOF

# Склеиваем очищенные прокси пользователя с шапкой конфига
sudo cat /etc/mihomo/user_warp[ТОЧКА]yaml | sudo tee -a /etc/mihomo/config[ТОЧКА]yaml > /dev/null
sudo rm -f /etc/mihomo/user_warp[ТОЧКА]yaml

# Дописываем PersistentKeepalive и жесткие правила раздельного туннелирования в самый конец файла
sudo tee -a /etc/mihomo/config[ТОЧКА]yaml > /dev/null << EOF
    keepalive: 25      # Удержание стабильной сессии за NAT домашнего роутера

rules:
  # Локальная домашняя сеть идет строго напрямую мимо VPN без внешних DNS запросов
  - GEOIP,lan,DIRECT,no-resolve
  
  # Системные репозитории Linux пускаем напрямую на максимальной скорости провайдера
  - DOMAIN-SUFFIX,raspberrypi[ТОЧКА]org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi[ТОЧКА]com,DIRECT
  - DOMAIN-SUFFIX,raspbian[ТОЧКА]org,DIRECT
  - DOMAIN-SUFFIX,debian[ТОЧКА]org,DIRECT
  
  # Весь остальной внешний интернет-трафик (включая репозиторий Homebridge) заворачиваем в туннель WARP
  - MATCH,WARP
EOF

# 4. Создание системной службы автозапуска (Systemd)
echo "  # # Настройка фоновой службы туннеля (Systemd)..."
sudo tee /etc/systemd/system/mihomo[ТОЧКА]service > /dev/null << EOF
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

# 6. Контрольное тестирование соединения
if curl -m 5 -sI https://repo[ТОЧКА]homebridge[ТОЧКА]io/stable/InRelease | grep -q "200"; then
    echo -e "\n  \${green}[УСПЕХ] Обход блокировок AWG 2.0 MASQUE успешно настроен и запущен!\${reset}"
    exit 0
else
    echo -e "\n  \${red}[ВНИМАНИЕ] Служба запущена, но тестовый пакет не прошел через Amnezia-туннель.\${reset}"
    echo "  Посмотрите подробный лог ошибок ядра: sudo journalctl -u mihomo -n 20"
    exit 1
fi
