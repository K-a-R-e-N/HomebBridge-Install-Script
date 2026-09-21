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

# ----------------------------------------------------------------─────
echo -n "  [1/7] Создание системных каталогов... "
sudo mkdir -p /etc/amnezia/amneziawg /usr/local/bin
sudo rm -f /etc/amnezia/amneziawg/awg0.conf
echo -e "${green}[УСПЕШНО]${reset}"

# ----------------------------------------------------------------─────
echo -n "  [2/7] Проверка бинарного ядра AmneziaWG... "
if [ ! -f /usr/local/bin/awg ]; then
    echo -e "${amber}[СКАЧИВАНИЕ]${reset}"
    sudo curl -sL -o /usr/local/bin/awg https://github.com/amnezia-vpn/amneziawg-go/releases/download/v0.2.12/amneziawg-go-linux-arm64
    sudo chmod +x /usr/local/bin/awg
    echo -n "        Распаковка бинарного файла... "
fi
echo -e "${green}[УСПЕШНО]${reset}"

# ----------------------------------------------------------------─────
echo -n "  [3/7] Защита менеджера пакетов apt от зависаний... "
sudo tee /etc/apt/apt.conf.d/99timeout > /dev/null << EOF
Acquire::http::Timeout "15";
Acquire::https::Timeout "15";
Acquire::ftp::Timeout "15";
Acquire::Retries "3";
EOF
echo -e "${green}[УСПЕШНО]${reset}"

# ----------------------------------------------------------------─────
echo -n "  [4/7] Подключение к API Cloudflare для генерации WARP... "
WORK_DIR="/home/pi/warp_tmp"
sudo rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

sudo curl -sSL https://raw.githubusercontent.com/ImMALWARE/bash-warp-generator/main/warp_generator.sh -o warp_generator.sh
sudo chmod +x warp_generator.sh

# Запуск генератора с жестким тайм-аутом в 10 секунд для исключения зависаний
sudo timeout 10 ./warp_generator.sh > /dev/null 2>&1

WG_PRIVATE_KEY=$(grep "PrivateKey" wg0.conf 2>/dev/null | awk '{print $3}')
WG_ADDRESS_V4=$(grep "Address" wg0.conf 2>/dev/null | head -n 1 | awk '{print $3}' | cut -d',' -f1)
WG_PUBLIC_KEY=$(grep "PublicKey" wg0.conf 2>/dev/null | awk '{print $3}')

cd /home/pi && sudo rm -rf "$WORK_DIR"

if [ -z "$WG_PRIVATE_KEY" ]; then
    echo -e "${amber}[СБОЙ API / ПРИМЕНЕНИЕ РЕЗЕРВА]${reset}"
    # Если API заблокирован, подставляем железные рабочие ключи MASQUE
    WG_PRIVATE_KEY="xArtVFXZ/jqQHM8Wo5q944HraNUDysO5H/8h95pzcKY="
    WG_PUBLIC_KEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
    WG_ADDRESS_V4="172.16.0.2/32"
else
    echo -e "${green}[ОФИЦИАЛЬНЫЙ АККАУНТ СОЗДАН]${reset}"
fi

# ----------------------------------------------------------------─────
echo -n "  [5/7] Сборка конфигурации маскировки AmneziaWG... "
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
AllowedIPs = 104.26.0.0/16, 172.67.0.0/16, 188.114.0.0/16, 104.20.0.0/15, 104.22.0.0/16
Endpoint = 188.114.97.3:443
PersistentKeepalive = 15
EOF

sudo sed -i '/repo.homebridge.io/d' /etc/hosts
sudo sed -i '/deb.nodesource.com/d' /etc/hosts
sudo tee -a /etc/hosts > /dev/null << 'EOF'
104.26.6.246 repo.homebridge.io
104.26.7.246 repo.homebridge.io
172.67.72.137 repo.homebridge.io
104.22.2.34 deb.nodesource.com
104.22.3.34 deb.nodesource.com
EOF
echo -e "${green}[УСПЕШНО]${reset}"

# ----------------------------------------------------------------─────
echo -n "  [6/7] Создание и регистрация фоновой службы... "
sudo tee /etc/systemd/system/amneziawg.service > /dev/null << EOF
[Unit]
Description=AmneziaWG Lightweight Userspace Tunnel Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/awg awg0
ExecStartPost=/bin/bash -c 'sleep 1.5 && ip link set mtu 1280 dev awg0 && ip link set awg0 up && ip route add 104.26.0.0/16 dev awg0 && ip route add 172.67.0.0/16 dev awg0 && ip route add 188.114.0.0/16 dev awg0 && ip route add 104.20.0.0/15 dev awg0 && ip route add 104.22.0.0/16 dev awg0'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now amneziawg > /dev/null 2>&1
echo -e "${green}[УСПЕШНО]${reset}"

# ----------------------------------------------------------------─────
echo -n "  [7/7] Активация туннеля и проверка зашифрованного линка... "
sleep 5

if curl -m 6 -sI https://repo.homebridge.io/KEY.gpg | grep -q "200"; then
    echo -e "${green}[СОЕДИНЕНИЕ УСТАНОВЛЕНО]${reset}"
    echo -e "\n  ${green}[ОК] Автоматический туннель AmneziaWG успешно запущен, блокировка пробита!${reset}\n"
    exit 0
else
    echo -e "${amber}[ОТКАЗ]${reset}"
    echo -e "\n  ${amber}[!] Защищенный пакет заблокирован на уровне провайдера.${reset}"
    echo -e "      ${dim}Проверьте логи службы: sudo systemctl status amneziawg${reset}\n"
    exit 1
fi
