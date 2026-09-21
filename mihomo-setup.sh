#!/bin/bash

# 1. Объявляем цветовые маркеры для красивого вывода
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

clear
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║              Автоматическая настройка обхода блокировок Mihomo              ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# 2. Умная защита от повторной генерации аккаунта Cloudflare
if [ -f /etc/mihomo/config.yaml ]; then
    echo -e "\n  ${yellow}[ИНФО] Конфигурация Mihomo уже создана ранее.${reset}"
    echo "  Перезапускаем и проверяем существующий туннель..."
    sudo systemctl restart mihomo > /dev/null 2>&1
    sleep 4
    if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
        echo -e "  ${green}[ОК] Старый туннель успешно запущен и работает!${reset}"
        exit 0
    fi
    echo "  [ИНФО] Старая сессия заблокирована или не отвечает. Перегенерируем профиль..."
fi

# 3. Создание системных директорий
echo -en "\n" ; echo "  # # Создание рабочих каталогов..."
sudo mkdir -p /usr/local/bin /etc/mihomo

# 4. Скачивание бинарного ядра Mihomo (чистый официальный релиз ARM64)
if [ ! -f /usr/local/bin/mihomo ]; then
    echo "  # # Скачивание и распаковка ядра Mihomo..."
    # Используем проверенное зеркало для скачивания, если сам GitHub барахлит
    sudo curl -L -o /usr/local/bin/mihomo.gz https://ghp.ci/https://github.com/MetaCubeX/mihomo/releases/download/v1.19.30/mihomo-linux-arm64-v1.19.30.gz > /dev/null 2>&1
    sudo gunzip -f /usr/local/bin/mihomo.gz
    sudo chmod +x /usr/local/bin/mihomo
fi

# 5. Автоматическая регистрация нового аккаунта WARP через API
echo "  # # Генерация нового официального профиля Cloudflare WARP..."
sudo curl -sSL https://raw.githubusercontent.com/ImMALWARE/bash-warp-generator/main/warp_generator.sh -o /tmp/warp_gen.sh
chmod +x /tmp/warp_gen.sh

# Запускаем генератор во временной папке tmp
cd /tmp && ./warp_gen.sh > /dev/null 2>&1

# Ювелирно вытаскиваем только IPv4 параметры WireGuard
WG_PRIVATE_KEY=$(grep "PrivateKey" /tmp/wg0.conf | awk '{print $3}')
WG_ADDRESS_V4=$(grep "Address" /tmp/wg0.conf | head -n 1 | awk '{print $3}' | cut -d',' -f1)
WG_PUBLIC_KEY=$(grep "PublicKey" /tmp/wg0.conf | awk '{print $3}')
WG_ENDPOINT=$(grep "Endpoint" /tmp/wg0.conf | awk '{print $3}')

# Очищаем временный мусор генератора
rm -f /tmp/warp_gen.sh /tmp/wg0.conf

# Если ключи пустые, прерываем скрипт
if [ -z "$WG_PRIVATE_KEY" ]; then
    echo -e "  ${red}[ОШИБКА] API Cloudflare отклонил запрос регистрации!${reset}"
    exit 1
fi

# 6. Сборка идеального config.yaml с раздельным туннелированием
echo "  # # Сборка config.yaml (IPv6: Выкл, Keepalive: 25с, Раздельный туннель)..."
sudo tee /etc/mihomo/config.yaml > /dev/null << EOF
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  bypass-lan: true   # Отсекаем домашнюю локальную сеть на уровне ядра

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
    server: $(echo $WG_ENDPOINT | cut -d':' -f1)
    port: $(echo $WG_ENDPOINT | cut -d':' -f2)
    ip: $WG_ADDRESS_V4 # Строго IPv4 (IPv6 полностью отключен)
    public-key: $WG_PUBLIC_KEY
    private-key: $WG_PRIVATE_KEY
    udp: true
    remote-dns-resolve: true
    keepalive: 25      # PersistentKeepalive для удержания сессии за NAT домашнего роутера

proxy-groups:
  - name: WARP
    type: select
    proxies:
      - "WARP"

rules:
  # Жёсткое раздельное туннелирование: домашняя сеть идет строго напрямую без внешних DNS запросов
  - GEOIP,lan,DIRECT,no-resolve
  
  # Системные обновления Debian и Raspberry Pi пускаем напрямую (на максимальной скорости провайдера)
  - DOMAIN-SUFFIX,raspberrypi.org,DIRECT
  - DOMAIN-SUFFIX,raspberrypi.com,DIRECT
  - DOMAIN-SUFFIX,raspbian.org,DIRECT
  - DOMAIN-SUFFIX,debian.org,DIRECT
  
  # Весь остальной внешний трафик (включая заблокированный Homebridge) заворачиваем в WARP
  - MATCH,WARP
EOF

# 7. Создание системного юнита Systemd для фонового автозапуска
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

# 8. Активация и запуск туннеля
sudo systemctl daemon-reload
sudo systemctl enable --now mihomo > /dev/null 2>&1

echo "  # # Запуск службы Mihomo. Ожидаем поднятия линка 5 секунд..."
sleep 5

# 9. Финальное контрольное тестирование связи
if curl -m 5 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[УСПЕХ] Обход блокировок успешно настроен!${reset}"
    echo "  Локальная сеть изолирована. IPv6 выключен. Туннель активен."
    exit 0
else
    echo -e "\n  ${red}[ВНИМАНИЕ] Служба Mihomo запущена, но пакеты не проходят через WARP.${reset}"
    echo "  Проверьте ошибки ядра командой: sudo journalctl -u mihomo -n 20"
    exit 1
fi
