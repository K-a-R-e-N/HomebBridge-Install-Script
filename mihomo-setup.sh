#!/bin/bash

# Настройка мягкой и контрастной цветовой палитры
cyan=$(tput setaf 6)
green=$(tput setaf 2)
amber=$(tput setaf 3)
dim=$(tput setaf 8)
reset=$(tput sgr0)

# Полностью вычищаем старые зависшие процессы и службы
sudo systemctl disable --now amneziawg > /dev/null 2>&1
sudo systemctl disable --now awg-quick@awg0 > /dev/null 2>&1
sudo killall -9 awg awg-quick mihomo > /dev/null 2>&1

echo "${cyan}╔═════════════════════════════════════════════════════════════════════════════╗${reset}"
echo "${cyan}║             Автоматическая настройка обхода блокировок AmneziaWG            ║${reset}"
echo "${cyan}╚═════════════════════════════════════════════════════════════════════════════╝${reset}"

echo -en "\n" ; echo "  # # Подготовка системных компонентов..."
sudo mkdir -p /etc/amnezia/amneziawg /usr/local/bin

# Принудительное удаление старого файла конфигурации
sudo rm -f /etc/amnezia/amneziawg/awg0.conf

# Скачивание официального бинарника ядра AmneziaWG
if [ ! -f /usr/local/bin/awg ]; then
    sudo curl -sL -o /usr/local/bin/awg https://github.com/amnezia-vpn/amneziawg-go/releases/download/v0.2.12/amneziawg-go-linux-arm64
    sudo chmod +x /usr/local/bin/awg
fi

# ЖЕСТКАЯ ЗАЩИТА APT-GET ОТ ЗАВИСАНИЙ: Устанавливаем тайм-аут соединения в 15 секунд
sudo tee /etc/apt/apt.conf.d/99timeout > /dev/null << EOF
Acquire::http::Timeout "15";
Acquire::https::Timeout "15";
Acquire::ftp::Timeout "15";
Acquire::Retries "3";
EOF

echo "  # # Автоматическое получение конфигурации Cloudflare WARP..."
WORK_DIR="/home/pi/warp_tmp"
sudo rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Скачиваем скрипт генератора
sudo curl -sSL https://raw.githubusercontent.com/ImMALWARE/bash-warp-generator/main/warp_generator.sh -o warp_generator.sh
sudo chmod +x warp_generator.sh

# Запускаем генерацию аккаунта
sudo ./warp_generator.sh > /dev/null 2>&1

# Считываем сгенерированные приватные ключи
WG_PRIVATE_KEY=$(grep "PrivateKey" wg0.conf 2>/dev/null | awk '{print $3}')
WG_ADDRESS_V4=$(grep "Address" wg0.conf 2>/dev/null | head -n 1 | awk '{print $3}' | cut -d',' -f1)
WG_PUBLIC_KEY=$(grep "PublicKey" wg0.conf 2>/dev/null | awk '{print $3}')

# Полностью вычищаем рабочую папку в хоуме
cd /home/pi && sudo rm -rf "$WORK_DIR"

# Подстраховка: если API Cloudflare был недоступен, применяем проверенные рабочие ключи MASQUE
if [ -z "$WG_PRIVATE_KEY" ]; then
    WG_PRIVATE_KEY="xArtVFXZ/jqQHM8Wo5q944HraNUDysO5H/8h95pzcKY="
    WG_PUBLIC_KEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
    WG_ADDRESS_V4="172.16.0.2/32"
fi

# Сборка конфига awg0.conf с расширенными пулами адресов
sudo tee /etc/amnezia/amneziawg/awg0.conf > /dev/null << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_ADDRESS_V4
MTU = 1280
Jc = 5
Jmin = 50
Jmax = 90
H1 = 1
H2 = 2
H3 = 3
H4 = 4

[Peer]
PublicKey = $WG_PUBLIC_KEY
# Добавлены расширенные пулы IP-адресов CDN Cloudflare для стабильного скачивания больших файлов
AllowedIPs = 104.26.0.0/16, 172.67.0.0/16, 188.114.0.0/16, 104.20.0.0/15, 104.22.0.0/16
Endpoint = 188.114.97.3:443
PersistentKeepalive = 15
EOF

# Жесткая привязка хостов к IP (Полный обход заблокированного DNS вашего провайдера)
sudo sed -i '/repo.homebridge.io/d' /etc/hosts
sudo sed -i '/deb.nodesource.com/d' /etc/hosts
sudo tee -a /etc/hosts > /dev/null << 'EOF'
104.26.6.246 repo.homebridge.io
104.26.7.246 repo.homebridge.io
172.67.72.137 repo.homebridge.io
104.22.2.34 deb.nodesource.com
104.22.3.34 deb.nodesource.com
EOF

# Создание системной фоновой службы напрямую для бинарника awg
sudo tee /etc/systemd/system/amneziawg.service > /dev/null << EOF
[Unit]
Description=AmneziaWG Lightweight Userspace Tunnel Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/awg awg0
# Оптимизированный роутинг: Endpoint переведен на порт 443 (имитация HTTPS трафика), изменены заголовки мусора Jc
ExecStartPost=/bin/bash -c 'sleep 1.5 && ip link set mtu 1280 dev awg0 && ip link set awg0 up && ip route add 104.26.0.0/16 dev awg0 && ip route add 172.67.0.0/16 dev awg0 && ip route add 188.114.0.0/16 dev awg0 && ip route add 104.20.0.0/15 dev awg0 && ip route add 104.22.0.0/16 dev awg0'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Принудительный запуск туннеля в системе
sudo systemctl daemon-reload
sudo systemctl enable --now amneziawg > /dev/null 2>&1

echo "  # # Инициализация зашифрованного линка. Ожидание 5 секунд..."
sleep 5

# Тестирование соединения напрямую до гарантированно рабочего файла KEY.gpg
if curl -m 6 -sI https://repo.homebridge.io/KEY.gpg | grep -q "200"; then
    echo -e "\n  ${green}[ОК] Автоматический туннель AmneziaWG успешно запущен, блокировка пробита!${reset}\n"
    exit 0
else
    echo -e "\n  ${amber}[!] Автоматическое соединение не удалось.${reset}"
    echo -e "      ${dim}Проверьте логи службы: sudo systemctl status amneziawg${reset}\n"
    exit 1
fi
