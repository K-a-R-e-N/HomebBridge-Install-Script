#!/bin/bash

# Настройка мягкой и контрастной цветовой палитры
cyan=\$(tput setaf 6)
green=\$(tput setaf 2)
amber=\$(tput setaf 3)
dim=\$(tput setaf 8)
reset=\$(tput sgr0)

# Полностью вычищаем старые зависшие процессы и службы
sudo systemctl disable --now amneziawg > /dev/null 2>&1
sudo systemctl disable --now awg-quick@awg0 > /dev/null 2>&1
sudo killall -9 awg awg-quick mihomo > /dev/null 2>&1

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║             Настройка обхода блокировок AmneziaWG (Вставка конфига)         ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

echo -en "\n" ; echo "  # # Подготовка системных компонентов..."
sudo mkdir -p /etc/amnezia/amneziawg /usr/local/bin

# 1. Скачивание официального бинарника ядра AmneziaWG
if [ ! -f /usr/local/bin/awg ]; then
    sudo curl -sL -o /usr/local/bin/awg https://github[ТОЧКА]com/amnezia-vpn/amneziawg-go/releases/download/v0[ТОЧКА]2[ТОЧКА]12/amneziawg-go-linux-arm64
    sudo chmod +x /usr/local/bin/awg
fi

# 2. Инструкция для пользователя
echo -e "\n  \${amber}ШАГ 1:\${reset} Откройте в браузере сайт:"
echo -e "         \${green}https://warp-generation[ТОЧКА]github[ТОЧКА]io\${reset}"
echo -e "\n  \${amber}ШАГ 2:\${reset} Справа найдите блок \${cyan}AmneziaWG\${reset} (самый первый блок!)"
echo -e "         и нажмите оранжевую кнопку \${amber}AWG 2.0 (1 вариант)\${reset}[ТОЧКА]"
echo -e "\n  \${amber}ШАГ 3:\${reset} Полностью скопируйте весь открывшийся текст (\${cyan}Ctrl+A\${reset}, затем \${cyan}Ctrl+C\${reset})[ТОЧКА]"
echo -e "\n  \${amber}ШАГ 4:\${reset} Сейчас откроется редактор[ТОЧКА] Вставьте скопированный текст (\${cyan}Ctrl+V\${reset}),"
echo -e "         нажмите \${cyan}Ctrl+O\${reset} -> \${cyan}Enter\${reset} (сохранить) и \${cyan}Ctrl+X\${reset} (выход)[ТОЧКА]"
echo -en "\n"
read -p "  По готовности нажмите [ENTER], чтобы открыть редактор и вставить текст... "

# Открываем текстовый редактор для вставки оригинального текста с сайта
sudo nano /etc/amnezia/amneziawg/awg0[ТОЧКА]conf

if [ ! -s /etc/amnezia/amneziawg/awg0[ТОЧКА]conf ]; then
    echo -e "\n  \${amber}Ошибка: Конфигурационный файл пустой[ТОЧКА] Действие отменено[ТОЧКА]\${reset}\n"
    exit 1
fi

echo -e "\n  # # Оптимизация сетевых параметров..."

# Вырезаем IPv6 маршруты, которые вешают сетевой стек Raspberry Pi
sudo sed -i '/ipv6:/d' /etc/amnezia/amneziawg/awg0[ТОЧКА]conf
sudo sed -i '/:,/d' /etc/amnezia/amneziawg/awg0[ТОЧКА]conf
sudo sed -i '/\[::\]/d' /etc/amnezia/amneziawg/awg0[ТОЧКА]conf

# Извлекаем локальный виртуальный IP-адрес, выданный Cloudflare
USER_TUN_IP=\$(grep -i "Address" /etc/amnezia/amneziawg/awg0[ТОЧКА]conf | awk '{print \$3}' | cut -d',' -f1)
USER_TUN_IP=\${USER_TUN_IP:-172[ТОЧКА]16[ТОЧКА]0[ТОЧКА]2/32}

# Извлекаем удаленный эндпоинт и порт
AWG_ENDPOINT=\$(grep -i "Endpoint" /etc/amnezia/amneziawg/awg0[ТОЧКА]conf | awk '{print \$3}')
AWG_PORT=\$(echo "\$AWG_ENDPOINT" | cut -d':' -f2)

# Подменяем заблокированные стандартные порты Cloudflare на случайные рабочие порты Amnezia
if [ "\$AWG_PORT" == "4500" ] || [ "\$AWG_PORT" == "2408" ]; then
    sudo sed -i 's/:4500/:3852/g' /etc/amnezia/amneziawg/awg0[ТОЧКА]conf
    sudo sed -i 's/:2408/:3852/g' /etc/amnezia/amneziawg/awg0[ТОЧКА]conf
fi

# Насильно прописываем PersistentKeepalive, чтобы линк не засыпал за NAT роутера
if ! grep -q "PersistentKeepalive" /etc/amnezia/amneziawg/awg0[ТОЧКА]conf; then
    sudo sed -i '/AllowedIPs/a PersistentKeepalive = 25' /etc/amnezia/amneziawg/awg0[ТОЧКА]conf
fi

# 3. Настройка системной фоновой службы (Исправлено: добавлены команды привязки IP и поднятия интерфейса)
sudo tee /etc/systemd/system/amneziawg[ТОЧКА]service > /dev/null << EOF
[Unit]
Description=AmneziaWG Lightweight Tunnel Daemon
After=network[ТОЧКА]target

[Service]
Type=simple
User=root
# Запуск туннеля
ExecStart=/usr/local/bin/awg awg0
# Исправлено: Сразу после запуска присваиваем IP и принудительно переводим интерфейс в режим UP
ExecStartPost=/bin/bash -c 'sleep 1 && ip address add \$USER_TUN_IP dev awg0 && ip link set mtu 1280 dev awg0 && ip link set awg0 up && ip route add 104[ТОЧКА]26[ТОЧКА]0[ТОЧКА]0/16 dev awg0'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 4. Принудительный мгновенный запуск туннеля в системе
sudo systemctl daemon-reload
sudo systemctl enable --now amneziawg > /dev/null 2>&1

echo "  # # Инициализация зашифрованного линка[ТОЧКА] Ожидание 5 секунд..."
sleep 5

# 5. Итоговая проверка связи до репозитория Homebridge
if curl -m 6 -sI https://repo[ТОЧКА]homebridge[ТОЧКА]io/stable/InRelease | grep -q "200"; then
    echo -e "\n  \${green}[ОК] Туннель AmneziaWG успешно запущен, блокировка пробита!\${reset}\n"
    exit 0
else
    echo -e "\n  \${amber}[!] Служба запущена, но соединение с Cloudflare отсутствует[ТОЧКА]\${reset}"
    echo -e "      \${dim}Попробуйте скопировать '2 вариант' или '3 вариант' AmneziaWG на сайте[ТОЧКА]\${reset}\n"
    exit 1
fi
