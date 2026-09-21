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
echo "${cyan}║             Настройка обхода блокировок AmneziaWG (Вставка конфига)         ║${reset}"
echo "${cyan}╚═════════════════════════════════════════════════════════════════════════════╝${reset}"

echo -en "\n" ; echo "  # # Подготовка системных компонентов..."
sudo mkdir -p /etc/amnezia/amneziawg /usr/local/bin

# 1. Скачивание официального бинарника ядра AmneziaWG
if [ ! -f /usr/local/bin/awg ]; then
    sudo curl -sL -o /usr/local/bin/awg https://github.com/amnezia-vpn/amneziawg-go/releases/download/v0.2.12/amneziawg-go-linux-arm64
    sudo chmod +x /usr/local/bin/awg
fi

# 2. Инструкция для пользователя
echo -e "\n  ${amber}ШАГ 1:${reset} Откройте в браузере сайт:"
echo -e "         ${green}https://warp-generation.github.io${reset}"
echo -e "\n  ${amber}ШАГ 2:${reset} Справа найдите блок ${cyan}AmneziaWG${reset} (самый первый блок!)"
echo -e "         и нажмите оранжевую кнопку ${amber}AWG 2.0 (1 вариант)${reset}."
echo -e "\n  ${amber}ШАГ 3:${reset} Полностью скопируйте весь открывшийся текст (${cyan}Ctrl+A${reset}, затем ${cyan}Ctrl+C${reset})."
echo -e "\n  ${amber}ШАГ 4:${reset} Сейчас откроется редактор. Вставьте скопированный текст (${cyan}Ctrl+V${reset}),"
echo -e "         нажмите ${cyan}Ctrl+O${reset} -> ${cyan}Enter${reset} (сохранить) и ${cyan}Ctrl+X${reset} (выход)."
echo -en "\n"
read -p "  По готовности нажмите [ENTER], чтобы открыть редактор и вставить текст... "

# Открываем текстовый редактор для вставки оригинального текста с сайта
sudo nano /etc/amnezia/amneziawg/awg0.conf

if [ ! -s /etc/amnezia/amneziawg/awg0.conf ]; then
    echo -e "\n  ${amber}Ошибка: Конфигурационный файл пустой. Действие отменено.${reset}\n"
    exit 1
fi

echo -e "\n  # # Оптимизация сетевых параметров..."

# Вырезаем IPv6 маршруты, которые вешают сетевой стек Raspberry Pi
sudo sed -i '/ipv6:/d' /etc/amnezia/amneziawg/awg0.conf
sudo sed -i '/:,/d' /etc/amnezia/amneziawg/awg0.conf
sudo sed -i '/\[::\]/d' /etc/amnezia/amneziawg/awg0.conf

# Извлекаем локальный виртуальный IP-адрес, выданный Cloudflare
USER_TUN_IP=$(grep -i "Address" /etc/amnezia/amneziawg/awg0.conf | awk '{print $3}' | cut -d',' -f1)
USER_TUN_IP=${USER_TUN_IP:-172.16.0.2/32}

# Извлекаем удаленный эндпоинт и порт
AWG_ENDPOINT=$(grep -i "Endpoint" /etc/amnezia/amneziawg/awg0.conf | awk '{print $3}')
AWG_PORT=$(echo "$AWG_ENDPOINT" | cut -d':' -f2)

# Подменяем заблокированные стандартные порты Cloudflare на случайные рабочие порты Amnezia
if [ "$AWG_PORT" == "4500" ] || [ "$AWG_PORT" == "2408" ]; then
    sudo sed -i 's/:4500/:3852/g' /etc/amnezia/amneziawg/awg0.conf
    sudo sed -i 's/:2408/:3852/g' /etc/amnezia/amneziawg/awg0.conf
fi

# Насильно прописываем PersistentKeepalive, чтобы линк не засыпал за NAT роутера
if ! grep -q "PersistentKeepalive" /etc/amnezia/amneziawg/awg0.conf; then
    sudo sed -i '/AllowedIPs/a PersistentKeepalive = 25' /etc/amnezia/amneziawg/awg0.conf
fi

# 3. Жесткая привязка хоста (Обход блокировки DNS провайдера)
sudo sed -i '/repo.homebridge.io/d' /etc/hosts
sudo tee -a /etc/hosts > /dev/null << 'EOF'
104.26.6.246 repo.homebridge.io
104.26.7.246 repo.homebridge.io
172.67.72.137 repo.homebridge.io
EOF

# 4. Настройка системной фоновой службы 
sudo tee /etc/systemd/system/amneziawg.service > /dev/null << EOF
[Unit]
Description=AmneziaWG Lightweight Tunnel Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/awg awg0
# Маршрутизируем подсети Cloudflare напрямую в интерфейс туннеля awg0
ExecStartPost=/bin/bash -c 'sleep 1 && ip address add $USER_TUN_IP dev awg0 && ip link set mtu 1280 dev awg0 && ip link set awg0 up && ip route add 104.26.0.0/16 dev awg0 && ip route add 172.67.0.0/16 dev awg0'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 5. Принудительный запуск туннеля в системе
sudo systemctl daemon-reload
sudo systemctl enable --now amneziawg > /dev/null 2>&1

echo "  # # Инициализация зашифрованного линка. Ожидание 5 секунд..."
sleep 5

# 6. Контрольное тестирование соединения с репозиторием
if curl -m 6 -sI https://repo.homebridge.io/stable/InRelease | grep -q "200"; then
    echo -e "\n  ${green}[ОК] Туннель AmneziaWG успешно запущен, блокировка пробита!${reset}\n"
    exit 0
else
    echo -e "\n  ${amber}[!] Служба запущена, но соединение с Cloudflare отсутствует.${reset}"
    echo -e "      ${dim}Попробуйте скопировать '2 вариант' или '3 вариант' AmneziaWG на сайте.${reset}\n"
    exit 1
fi
