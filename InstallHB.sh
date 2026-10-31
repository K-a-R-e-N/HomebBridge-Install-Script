#!/bin/bash
yellow=$(tput setaf 3 2>/dev/null || tput setf 6)
red=$(tput setaf 1 2>/dev/null || tput setf 4)
green=$(tput setaf 2 2>/dev/null || tput setf 2)
reset=$(tput sgr0)

cmdkey=0 ; ME=$(basename "$0") ; cd ~ || exit 1 ; clear


# =========================================================================================
# Запрашиваем пароль sudo один раз на самом старте, чтобы не разрывать логи функций
# =========================================================================================
echo "  # # Для работы скрипта необходимы права суперпользователя."
sudo -v || exit 1
# Запускаем фоновое обновление и сохраняем PID процесса в переменную SUDO_PID
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
# Функция очистки, которая убьет фоновый sudo при выходе из основного скрипта
cleanup() {
    if kill -0 "$SUDO_PID" 2>/dev/null; then
        kill "$SUDO_PID" 2>/dev/null
    fi
}
# Привязываем функцию к событию завершения скрипта (EXIT)
trap cleanup EXIT
# =========================================================================================

# # # # # # # # # # # # # # # # 
BackupsFolder=~/HB_Backup
# # # # # # # # # # # # # # # # 

function Zagolovok {
echo -en "${yellow} \n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                 $ZI HomeBridge и его зависимостей.                  ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n ${reset}"
}

function GoToMenu {
    GoToMenuInfo="Чтобы продолжить, введите"
    while :
    do
        clear ; CheckBackUp=0 ; BackupRecovery=0
        ZI="  Установка" && Zagolovok 
        echo -en "\n"
        echo "     ┌─ Выберите действие: ──────────────────────────────────────────────┐"
        echo "     │                                                                   │"
        echo -en "\n" 
        echo "           1 - Установка Homebridge на чистой системе $InstallInfo"
        echo -en "\n"
        echo "           2 - Установка Homebridge с полным удалением старой версии $ReinstallInfo"
        echo -en "\n"
        echo "           3 - Полное удаление Homebridge с очисткой системы $UninstallInfo"
        echo -en "\n"
        echo "           4 - Обновление Homebridge до актуальной версии $UpdatingInfo"
        echo -en "\n"
        echo "           5 - Полное удаление Node.js и его хвостов из системы"
        echo -en "\n"
        echo "           0 - Завершение работы с самоудалением скрипта"
        echo -en "\n"
        echo "     │                                                                   │"
        echo "     └────────────────────────────────────────────── H - Вызов справки ──┘"
        echo -en "\n"
        echo -e "\a"
        echo "           $GoToMenuInfo номер пункта и нажмите на Enter"
        echo -e "\a"
        read -r item
        printf "\n"
        case "$item" in
            0) 	RremovalItself ;;
            1) 	ReinstallInfo="" ; InstallScript ;;
            2) 	cmdkey=1 ; UninstallScript ; cmdkey=0 ; InstallScript ;;
            3) 	ReinstallInfo="" ; UninstallScript ;;
            4) 	UpdatingInfo="" ; UpdatingScript ;;
            5) 	UninstallNodeJS ;;
            D|d) 	RremovalItself ;;
            H|h) 	print_help ;;
            *) 	clear && GoToMenuInfo="Попробуйте еще раз ввести" ;;
        esac
    done
}


function СheckingInstalledPackage() {
    local InstalledPackageKey=0
    echo -en "\n" ; echo -n "  # # Проверка на ранее установленную версию..."

    if dpkg -s homebridge 2>/dev/null | grep -q "Status: install ok installed"; then
        echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge как системный пакет..."
        InstallInfo="${green}[уже установлен]${reset}"
        InstalledPackageKey=1
        
    elif dpkg -s nodejs 2>/dev/null | grep -q "Status: install ok installed"; then
        if command -v npm >/dev/null 2>&1 && npm list -g --depth=0 2>/dev/null | grep -q homebridge; then
            echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge из NPM..."
            InstallInfo="${green}[уже установлен]${reset}"
            InstalledPackageKey=1
        else
            NODE_VER=$(node -v 2>/dev/null | tr -d ' ' || echo "неизвестно")
            echo -en "\n" ; echo "     - В системе уже установлен пакет Node.js ${green}$NODE_VER${reset}, но HomeBridge не установлен..."
            # Наличие чистого NodeJS больше не взводит триггер ошибки InstalledPackageKey=1
            [ "$cmdkey" -ne 1 ] && InstallInfo="${red}[установлен NodeJS]${reset}"
        fi
    fi
if [ "$InstalledPackageKey" -eq 1 ]; then
        # Автоматически вычисляем точный путь к скрипту с заменой домашней папки на тильду ~
        local SCRIPT_PATH="${0/#$HOME/\~}"

        if [ "$cmdkey" -eq 1 ]; then
            # Вариант вывода для ТИХОГО режима (по ключам)
            echo -e "\n\n${red}Критическая ошибка: Автоматическая установка прервана, компоненты уже есть в системе.${reset}"
            echo -e "\n  ${yellow}Что делать дальше? Используйте один из вариантов:${reset}"
            echo -e "  1. Запустить полную переустановку в тихом режиме (с предварительной очисткой):"
            echo -e "     ${green}bash $SCRIPT_PATH -r -d${reset}"
            echo -e "  2. Запустить обновление Homebridge до актуальной версии в тихом режиме:"
            echo -e "     ${green}bash $SCRIPT_PATH -f -d${reset}"
            echo -e "  3. Запустить скрипт в интерактивном режиме для выбора действий через меню:"
            echo -e "     ${green}bash $SCRIPT_PATH${reset}\n"
            exit 1
        else
            # Вариант вывода для ИНТЕРАКТИВНОГО режима (через меню)
            echo -e "\n"
            echo "    ┌─ Что необходимо сделать? ──────────────────────────────────────────┐"
            echo "    │                                                                    │"
            echo "          1 - Полностью удалить старую версию и установить заново"
            echo "          2 - Попробовать обновить текущую установку до актуальной"
            echo "          0 - Отменить операцию и вернуться в главное меню"
            echo "    │                                                                    │"
            echo "    └────────────────────────────────────────────────────────────────────┘"
            echo -e "\n  ${yellow}Шпаргалка: запуск этих действий одной строкой из консоли (тихий режим):${reset}"
            echo -e "  • Полная переустановка:   ${green}bash $SCRIPT_PATH -r -d${reset}"
            echo -e "  • Быстрое обновление:     ${green}bash $SCRIPT_PATH -f -d${reset}\n"
            
            while true; do
                echo -n "    Введите номер действия (0-2) или буквы (y/n): "
                read -r -n 1 CHOICE_OVER
                echo
                case $CHOICE_OVER in
                    1|y|Y|[дД])
                        echo -e "\n  ${yellow}Запуск процесса полной переустановки...${reset}"
                        sleep 1
                        cmdkey=1 ; UninstallScript ; cmdkey=0 ; InstallScript
                        return 1
                        ;;
                    2)
                        echo -e "\n  ${yellow}Запуск процесса обновления...${reset}"
                        sleep 1
                        UpdatingScript
                        return 1
                        ;;
                    0|n|N|[нН])
                        echo -e "\n  ${yellow}Операция отменена. Возврат в главное меню...${reset}"
                        sleep 1
                        return 1
                        ;;
                    *)
                        echo -e "       ${red}Неверный ввод. Выберите пункт меню (0-2) или (y/n)${reset}"
                        ;;
                esac
            done
        fi
    fi
return 0
}

function BackUpScript() {
    # Создаем папку от имени текущего пользователя
	[ ! -d "$BackupsFolder" ] && mkdir -p "$BackupsFolder" && chmod 755 "$BackupsFolder"

    # Бэкап основного рабочего конфига современного Homebridge
    if [ -f /var/lib/homebridge/config.json ]; then
        sudo cp -f /var/lib/homebridge/config.json "$BackupsFolder/config.json.main.$(date +%s)" >/dev/null 2>&1
        CheckBackUp=1
    fi

    # Безопасный бэкап папки с ротируемыми копиями config.json.* через find
    HA_SOURCE=/var/lib/homebridge/backups/config-backups
    if [ -d "$HA_SOURCE" ]; then
        find "$HA_SOURCE" -maxdepth 1 -type f -name "config.json.*" -exec sudo cp -f {} "$BackupsFolder" \; >/dev/null 2>&1
        CheckBackUp=1
    fi

    # Бэкап из старого пути /var/homebridge
    HA_SOURCE=/var/homebridge
    if [ -f "$HA_SOURCE/config.json" ]; then
        sudo cp -f "$HA_SOURCE/config.json" "$BackupsFolder/config.json.old_var.$(date +%s)" >/dev/null 2>&1
        CheckBackUp=1
    fi

    # Бэкап из домашней папки пользователя ~/.homebridge
    HA_SOURCE=~/.homebridge
    if [ -f "$HA_SOURCE/config.json" ]; then
        sudo cp -f "$HA_SOURCE/config.json" "$BackupsFolder/config.json.user.$(date +%s)" >/dev/null 2>&1
        CheckBackUp=1
    fi

	if [ "$CheckBackUp" -eq 1 ]; then
    	sudo chown -R "$(id -u):$(id -g)" "$BackupsFolder"
    	echo -en "\n" ; echo "  # # Создание резервной копии конфигурационных файлов HomeBridge..."
	fi
}

function CheckRepositoryAccess {
    echo -en "\n" ; echo -n "  # # Проверка доступности репозитория Homebridge..."

    #Сначала безопасно создаем ключ из встроенного текста (без curl)
    sudo mkdir -p /usr/share/keyrings
    sudo tee /usr/share/keyrings/homebridge.gpg > /dev/null << 'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=Mh06
-----END PGP PUBLIC KEY BLOCK-----
EOF

    #Проверяем доступность именно сервера репозитория пакетов!
    if curl -m 4 -sI https://repo.homebridge.io | grep -q "Etag\|Server\|Cloudflare\|200\|301\|302\|404"; then
        echo -e " ${green}[Доступно]${reset}"
        return 0
    fi

    bg_red=$(tput setab 1)$(tput setaf 7)
    echo -e "\n"
    echo "  ╔═════════════════════════════════════════════════════════════════════════════╗"
    echo -e "  ║               ${bg_red} КРИТИЧЕСКАЯ ОШИБКА: РЕПОЗИТОРИЙ НЕДОСТУПЕН! ${reset}                 ║"
    echo "  ╚═════════════════════════════════════════════════════════════════════════════╝"
    
    echo -e "\n    ${yellow}Адрес назначения:${reset} https://repo.homebridge.io"
    
    echo -e "\n    ${yellow}Возможные причины ответа сервера:${reset}"
    echo "    • Сетевые адреса Cloudflare заблокированы вашим провайдером (РКН)."
    echo "    • На плате SprutHub отсутствует внешнее интернет-соединение."
    echo "    • Системные DNS-серверы не могут разрешить имя хоста."
    echo -en "\n"
    
    echo "    ┌─────────────────────────────────────────────────────┐"
    echo "    │                                                     │"
    echo "    │  1. Автоматически настроить сеть через AmneziaWG    │"
    echo "    │  2. Отказаться и выйти в главное меню               │"
    echo "    │                                                     │"
    echo "    └─────────────────────────────────────────────────────┘"
    echo -en "\n"
    
    while true; do
        echo -n "    Введите номер пункта (1-2): "
        read -r NET_CHOICE
        case $NET_CHOICE in
            1|y|Y|[дД])
                clear
                SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
                
                if [ -f "$SCRIPT_DIR/mihomo-setup.sh" ]; then
                    chmod +x "$SCRIPT_DIR/mihomo-setup.sh"
                    bash "$SCRIPT_DIR/mihomo-setup.sh"

                    echo "  # # Проверка связи после настройки туннеля..."
                    if curl -m 6 -sI https://repo.homebridge.io | grep -q "Etag\|Server\|Cloudflare\|200\|301\|302\|404"; then
                        echo -e "       ${green}[ОК] Сеть успешно восстановлена! Продолжаем...${reset}"
                        return 0
                    else
                        echo -e "       ${red}Внимание: Репозиторий всё ещё заблокирован провайдером${reset}"
                        return 1
                    fi
                else
                    echo -e "       ${red}Ошибка: Соседний файл $SCRIPT_DIR/mihomo-setup.sh не найден!${reset}"
                    return 1
                fi
                ;;
            2|n|N|[нН])
                echo -e "       ${yellow}Действие отменено пользователем. Возврат в главное меню...${reset}"
                sleep 2
                return 1
                ;;
            *)
                echo -e "       ${red}Неверный ввод. Пожалуйста, введите цифру 1 или 2${reset}"
                ;;
        esac
    done
}

function InstallScript() {
    clear ; CheckBackUp=0 ; BackupRecovery=0
    ZI="  Установка" && Zagolovok

    ##################################
	# Запускаем проверку с интерактивным меню и шпаргалкой внутри
    СheckingInstalledPackage
    if [ $? -ne 0 ]; then
        # Если внутри функции запустилось обновление/удаление или была отмена — выходим!
        return
    fi
    # Сюда скрипт перейдет, только если система изначально была полностью чистая
    echo -e " ${green}[Не обнаружено]${reset}"
    ##################################

    CheckRepositoryAccess || { sleep 1; GoToMenu; return; }

    BackUpScript

    ##################################
    echo -en "\n" ; echo -n "  # # Сброс системных блокировок и подготовка окружения..."
    sudo killall -9 apt apt-get dpkg 2>/dev/null
    sleep 1
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/lib/dpkg/lock
    sudo dpkg --configure -a >/dev/null 2>&1
    sudo mkdir -p /etc/apt/keyrings
    echo -e " ${green}[Готово]${reset}"
    ##################################
    echo -en "\n" ; echo -n "  # # Очистка старых репозиториев Node.js и Homebridge..."
    sudo rm -f /etc/apt/keyrings/nodesource.gpg /etc/apt/sources.list.d/nodesource* /etc/apt/sources.list.d/homebridge*
    echo -e " ${green}[Готово]${reset}"
    ##################################
	echo -e "\n  # # Обновление индексов репозиториев..."
    sudo apt-get update -y 2>&1 | while read -r line; do
        if echo "$line" | grep -qE "Hit:|Get:|Ign:|Удл:|Всэ:|Игн:"; then
            clean_line=$(echo "$line" | tr -d '\r' | awk '{$1=$1;print}' | cut -c1-55)
            printf "\n\033[K       %s\033[1A" "$clean_line"
        fi
    done
    printf "\n\033[K\033[1A\r\033[K  # # Обновление индексов репозиториев... ${green}[Готово]${reset}\n"
    ##################################
    echo -en "\n" ; echo -n "  # # Установка базовых системных пакетов..."
    sudo apt-get install -y ca-certificates curl gnupg 2>&1 | while read -r line; do
        if echo "$line" | grep -qE "Unpacking|Setting up"; then printf "."; fi
    done
    echo -e " ${green}[Готово]${reset}"
    ##################################
    echo -en "\n" ; echo -n "  # # Импорт PGP-ключа и регистрация репозитория Homebridge..."
    curl -sSfL https://repo.homebridge.io/KEY.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/homebridge.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/homebridge.gpg] https://repo.homebridge.io stable main" | sudo tee /etc/apt/sources.list.d/homebridge.list > /dev/null
    echo -e " ${green}[Готово]${reset}"
    ##################################
	# echo -en "\n" ; echo -n "  # # Интеграция официального репозитория Node.js 24.x..."
	# Define the desired Node.js major version
	# NODE_MAJOR=24
	# Download the new repository's GPG key and save it in the keyring directory
	#curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg > /dev/null 2>&1
	# Add the new repository's source list with its GPG key for package verification
	# echo "Types: deb
	#URIs: https://deb.nodesource.com/node_${NODE_MAJOR}.x/
	# Suites: nodistro
	# Components: main
	#Signed-By: /etc/apt/keyrings/nodesource.gpg" | sudo tee /etc/apt/sources.list.d/nodesource.sources
	# echo -e " ${green}[Готово]${reset}"
    ##################################
	# echo -en "\n" ; echo -n "  # # Установка Node.js..."
	# sudo apt-get install -y nodejs 2>&1 | while read -r line; do if echo "$line" | grep -qE "Unpacking|Setting up"; then printf "."; fi; done
	# echo -e " ${green}[Готово]${reset}"
    ##################################
	echo -e "\n  # # Проверка обновлений перед зависимостями..."
    sudo apt-get update -y 2>&1 | while read -r line; do
        if echo "$line" | grep -qE "Hit:|Get:|Ign:|Удл:|Всэ:|Игн:"; then
            clean_line=$(echo "$line" | tr -d '\r' | awk '{$1=$1;print}' | cut -c1-50)
            printf "\n\033[K       %s\033[1A" "$clean_line"
        elif echo "$line" | grep -qE "Err:|Failed|Error|E:|W:|Ошб:"; then
            echo -e "\n${red}    [ОШИБКА РЕПОЗИТОРИЯ]: $line${reset}"
        fi
    done
    printf "\n\033[K\033[1A\r\033[K  # # Проверка обновлений перед зависимостями... ${green}[Готово]${reset}\n"
    ##################################
	echo -en "\n" ; echo -n "  # # Установка пакетов gcc g++ make python3 для сборки плагинов..."
    sudo apt-get install -y gcc g++ make python3 2>&1 | while read -r line; do
        if echo "$line" | grep -qE "Unpacking|Setting up|Preparing to unpack"; then
            printf "."
        elif echo "$line" | grep -qE "Err:|Failed|Error|E:|W:"; then
            echo -e "\n${red}    [ОШИБКА APT]: $line${reset}"
        fi
    done
    echo -e " ${green}[Готово]${reset}"
    ##################################
	echo -en "\n" ; echo -n "  # # Установка пакета libavahi-compat-libdnssd-dev..."
    sudo apt-get install -y libavahi-compat-libdnssd-dev 2>&1 | while read -r line; do
        if echo "$line" | grep -qE "Unpacking|Setting up|Preparing to unpack"; then
            printf "."
        elif echo "$line" | grep -qE "Err:|Failed|Error|E:|W:"; then
            echo -e "\n${red}    [ОШИБКА APT]: $line${reset}"
        fi
    done
    echo -e " ${green}[Готово]${reset}"
    ##################################
    echo -en "\n" ; echo -n "  # # Установка HomeBridge... "
    # Запускаем установку в фоне, перенаправляя вывод во временный файл
    sudo apt-get install homebridge -y > /tmp/apt_install.log 2>&1 &
    APT_PID=$! # Запоминаем ID процесса установки

    # Массив символов для анимации крутящегося спиннера
    spinner=( '╱' '─' '╲' '│' )
    
    # Крутим спиннер, пока процесс установки жив
    while kill -0 "$APT_PID" 2>/dev/null; do
        for sym in "${spinner[@]}"; do
            # Исправлено регулярное выражение: добавлен захват пробелов и очистка скрытых символов dpkg через sed
            current_act=$(tail -n 1 /tmp/apt_install.log 2>/dev/null | tr -d '\r' | sed 's/\r//g' | grep -oE "(Unpacking|Setting up|Preparing to unpack)[[:space:]]+[a-zA-Z0-9.-]+" | head -n 1)

            # Выводим строку, очищая предыдущий след в консоли
            printf "\r\033[K  ${yellow}%s${reset} # # Установка HomeBridge... %s" "$sym" "$current_act"
            sleep 0.1
        done
    done

    # Проверяем, как завершился процесс
    wait "$APT_PID"
    if [ $? -eq 0 ]; then
        printf "\r\033[K  # # Установка HomeBridge... ${green}[Готово]${reset}\n"
    else
        printf "\r\033[K  ${red}✘${reset} # # Установка HomeBridge... ${red}[ОШИБКА APT]${reset}\n"
        echo -e "${red}"
        tail -n 5 /tmp/apt_install.log # Показываем последние 5 строк лога с ошибкой
        echo -e "${reset}"
    fi
    rm -f /tmp/apt_install.log

    ##################################
    echo -en "\n" ; echo -n "  # # Интеграция в Systemd, активация и запуск демона Homebridge..."
    sudo systemctl daemon-reload > /dev/null 2>&1
    sudo systemctl enable homebridge > /dev/null 2>&1
    sudo systemctl restart homebridge > /dev/null 2>&1
    echo -e " ${green}[Успешно]${reset}"
    ##################################
	
    # Восстановление резервной копии происходит молча, если файлов нет
    if [ -d "$BackupsFolder" ] && [ "$(ls -A "$BackupsFolder" 2>/dev/null)" ]; then
        echo -en "\n" ; echo -n "  # # Восстановление резервной копии HomeBridge..."
        BackupRecovery=1
        if [ ! -d /var/lib/homebridge/backups/config-backups ] ; then 
            sudo mkdir -p /var/lib/homebridge/backups/config-backups && sudo chmod 777 /var/lib/homebridge/backups/config-backups
        fi
        
        sudo cp -f "$BackupsFolder"/config.json.* /var/lib/homebridge/backups/config-backups/ 2>/dev/null
        
        LATEST_CONF=$(ls -t "$BackupsFolder"/config.json.* 2>/dev/null | head -n 1)
        if [ -n "$LATEST_CONF" ]; then
            sudo cp -f "$LATEST_CONF" /var/lib/homebridge/config.json
            
            # Проверяем, успела ли система создать пользователя homebridge перед chown
            if id "homebridge" >/dev/null 2>&1; then
                sudo chown homebridge:homebridge /var/lib/homebridge/config.json
            else
                sudo chmod 664 /var/lib/homebridge/config.json
            fi
            sudo systemctl restart homebridge > /dev/null 2>&1
        fi

        rm -f "$BackupsFolder"/config.json.* 2>/dev/null
        echo -e " ${green}[Готово]${reset}"
    fi

# Вытаскиваем именно последний порт из конфига (порт веб-интерфейса)
HB_PORT=$(grep -o '"port":\s*[0-9]*' /var/lib/homebridge/config.json 2>/dev/null | grep -o '[0-9]*' | tail -n 1)
# Если переменная пустая (файл не найден, поврежден или пуст) — принудительно ставим стандартный 8581
if [ -z "$HB_PORT" ]; then
    HB_PORT=8581
fi

# Получаем IP-адрес (берем первый из списка, если их несколько)
HB_IP=$(hostname -I | awk '{print $1}')

# Безопасно считываем реальную установленную версию Homebridge
FINAL_HB_VERSION=$(dpkg-query -W -f='${Version}' homebridge 2>/dev/null || echo "Ошибка определения")

# Считываем версию Node.js (приоритет изолированной версии Homebridge на Debian 13)
if [ -f /opt/homebridge/bin/node ]; then
    NODE_VERSION_DISPLAY=$(/opt/homebridge/bin/node -v 2>/dev/null | tr -d ' ')
else
    NODE_VERSION_DISPLAY=$(node -v 2>/dev/null | tr -d ' ' || echo "неизвестно")
fi

echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║              ${green}Установка HomeBridge и его зависимостей завершена${reset}              ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
echo "    ┌──────────── Полезная информация для работы с HomeBridge ────────────┐"
echo "    │                                                                     │"
echo "    │                     Установленная версия: ${green}$FINAL_HB_VERSION${reset}                    │" 
echo "    │                                                                     │"
echo "    │             Доступ к веб-интерфейсу HomeBridge по адресу:           │"
echo "    │                      ${green}http://$HB_IP:$HB_PORT/${reset}                      │"
echo "    │                                                                     │"
echo "    │                  Редактирование файла конфигурации                  │"
echo "    │              ${green}sudo nano /var/lib/homebridge/config.json${reset}              │"
echo "    │                                                                     │"
if [ "$CheckBackUp" -eq 1 ]; then
echo "    │               Путь к восстановленным резервным копиям:              │"
echo "    │             ${green}/var/lib/homebridge/backups/config-backups/${reset}              │"
echo "    │                                                                     │"
fi
echo "    │               Путь хранения - ${green}/var/lib/homebridge${reset}                   │"
echo "    │             Путь к плагинам - ${green}/var/lib/homebridge/node_modules${reset}      │"
echo "    │                                                                     │"
echo "    │                       Перезагрузка HomeBridge                       │"
echo "    │                       ${green}sudo hb-service restart${reset}                       │"
echo "    │                                                                     │"
echo "    │                    Запустит HB - ${green}sudo hb-service start${reset}              │"
echo "    │                  Остановить HB - ${green}sudo hb-service stop${reset}               │"
echo "    │                                                                     │"
echo "    │              Просмотр журналов - ${green}sudo hb-service logs${reset}               │"
echo "    │                                                                     │"
echo "    │                    Установка и удаление плагинов                    │"
echo "    │               ${green}sudo hb-service add homebridge-example${reset}                │"
echo "    │               ${green}sudo hb-service remove homebridge-example${reset}             │"
echo "    │                                                                     │"
echo "    │                      Войти в Homebridge Shell                       │"
echo "    │                            ${green}sudo hb-shell${reset}                            │"
echo "    │                                                                     │"
echo "    └─────────────────────────────────────────────────────────────────────┘"
echo "                                 ┌ Установленная версия Node.js ┐"
echo "                                 │           ${green}$NODE_VERSION_DISPLAY${reset}           │"
echo "                                 └──────────────────────────────┘"
echo -e "\a"

InstallInfo="${green}[OK]${reset}"

if [ "$cmdkey" -eq 1 ]; then
    sleep 5
    return
fi

echo -n "${green}           Нажмите Enter, чтобы вернуться в главное меню...${reset}"
read -r
return
}


function UninstallScript() {
clear ; CheckBackUp=0 ; BackupRecovery=0
ZI="   Удаление" && Zagolovok

echo -en "\n" ; echo "  # # Остановка и завершение процесса Homebridge..."
sudo hb-service stop > /dev/null 2>&1
sudo systemctl stop homebridge > /dev/null 2>&1
sudo service homebridge stop > /dev/null 2>&1
sudo pm2 stop all > /dev/null 2>&1
sudo killall -w -s 9 -u homebridge > /dev/null 2>&1

# Обязательно делаем бэкап перед тем, как всё снести
BackUpScript

echo -en "\n" ; echo "  # # Деинсталляция пакета HomeBridge..."
sudo apt-get remove homebridge -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление репозитория и ключей Homebridge..."
sudo rm -f /etc/apt/sources.list.d/homebridge.list
sudo rm -f /usr/share/keyrings/homebridge.gpg

#echo -en "\n" ; echo "  # # Удаление репозитория NodeJS..."
#sudo rm -rf /etc/apt/sources.list.d/chris-lea-node_js-*

echo -en "\n" ; echo "  # # Деинсталляция всех плагинов и конфигураций Homebridge..."
sudo apt-get purge homebridge -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление пользователя homebridge..."
sudo pkill -u homebridge > /dev/null 2>&1
sudo userdel -f homebridge > /dev/null 2>&1


echo -en "\n" ; echo "  # # Удаление служб из списка автозагрузки..."
sudo update-rc.d homebridge remove > /dev/null 2>&1
sudo rm -f /etc/init.d/homebridge
sudo rm -rf /etc/systemd/system/homebridge*
sudo rm -rf /etc/systemd/system/multi-user.target.wants/homebridge*
sudo systemctl --system daemon-reload > /dev/null

echo -en "\n" ; echo "  # # Удаление хвостов для возможности последующей нормальной установки..."
sudo rm -rf /usr/lib/node_modules/homebridge* /usr/bin/homebridge* /etc/default/homebridge* /var/lib/homebridge*


echo -en "\n" ; echo "  # # Удаление хвостов от плагинов..."
sudo rm -rf /usr/bin/ps4-waker
sudo rm -rf /usr/lib/node_modules/ps4-waker

echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "   ${green}Удаление Homebridge, а так же всех его плагинов с конфигурациями завершено${reset}"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

UninstallInfo="${green}[OK]${reset}"

if [ "$cmdkey" -eq 1 ]; then
	sleep 5
	return
fi

echo -n "${green}           Нажмите Enter, чтобы вернуться в главное меню...${reset}"
read -r
return
}



function UpdatingScript() {
    clear ; CheckBackUp=0 ; BackupRecovery=0
    ZI=" Обновление" && Zagolovok
    CheckRepositoryAccess || { sleep 1; return 1; }

    # Перед любым обновлением обязательно страхуемся бэкапом
    BackUpScript

    echo -en "\n" ; echo "  # # Обновление индексов пакетов..."
    sudo apt-get update -y > /dev/null 2>&1

    echo -en "\n" ; echo "  # # Обновление HomeBridge..."
    # Флаг --only-upgrade обновит только Homebridge, не трогая остальную операционную систему
    sudo apt-get install --only-upgrade homebridge -y > /dev/null 2>&1
    ##################################
    # echo -en "\n" ; echo "  # # Обновление встроенного окружения Node.js до ветки 24..."
    # Проверяем, обновился ли бинарник hb-service, и обновляем внутренний Node.js
    # if command -v hb-service >/dev/null 2>&1; then
    #     sudo hb-service update-node 24 > /dev/null 2>&1
    # fi
    ##################################
    if [ -f /opt/homebridge/bin/node ]; then
        echo -en "\n" ; echo "  # # Среда Node.js изолирована внутри пакета и обновилась автоматически."
    else
        echo -en "\n" ; echo "  # # Обновление внешнего окружения Node.js до актуальной LTS версии..."
        if command -v hb-service >/dev/null 2>&1; then
            sudo hb-service update-node lts > /dev/null 2>&1
        fi
    fi

    echo -en "\n"
    echo -en "\n"
    echo "╔═════════════════════════════════════════════════════════════════════════════╗"
    echo "   ${green}Обновление Homebridge успешно завершено!${reset}"
    echo "╚═════════════════════════════════════════════════════════════════════════════╝"
    echo -e "\a"

    UpdatingInfo="${green}[OK]${reset}"

    if [ "$cmdkey" -eq 1 ]; then
        sleep 5
        return
    fi

    echo -n "${green}           Нажмите Enter, чтобы вернуться в главное меню...${reset}"
    read -r
    return
}


function UninstallNodeJS() {
    clear
    ZI=" Удаление Node" && Zagolovok
    echo -en "\n" ; echo "${red}  # # ВНИМАНИЕ: Будет произведено ПОЛНОЕ удаление Node.js и всех модулей!${reset}"
    echo "  Это действие может нарушить работу других компонентов SprutHub."
    echo -n "  Вы уверены, что хотите продолжить? (yes/no): "
    read -r -n 1 confirm
    echo
    # Проверка регулярным выражением: принимает y, Y, д, Д
    if [[ ! "$confirm" =~ ^[yYдД]$ ]]; then
        echo -e "\n  ${yellow}Операция отменена пользователем.${reset}"
        sleep 2
        return 1
    fi

    echo -en "\n" ; echo -n "  # # Удаление системы и очистка хвостов Node.js..."
    # Вызов оригинального скрипта деинсталляции через curl
    sudo curl -sfL https://gist.githubusercontent.com/oznu/312b54364616082c3c1e0b6b02351f0e/raw/remove-node.sh | sudo bash > /dev/null 2>&1
    echo -e " ${green}[Готово]${reset}"

    echo -en "\n"
    echo "╔═════════════════════════════════════════════════════════════════════════════╗"
    echo "   ${green}Окружение Node.js полностью удалено из вашей системы!${reset}"
    echo "╚═════════════════════════════════════════════════════════════════════════════╝"
    echo -e "\a"
    
    echo -n "${green}           Нажмите Enter, чтобы вернуться в главное меню...${reset}"
    read -r
    return 0
}


function RremovalItself() {
    echo -en "\n" ; echo "                   Самоудаление папки со скриптом установки...  " ; cd
    
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    sudo rm -rf "$SCRIPT_DIR"
    if [ $? -eq 0 ]; then
        echo "                ${green}[Успешно удалено]${reset} - ${red}Завершение работы скрипта...${reset}" ; echo -en "\n"
    else
        echo "            ${red}[Удаление не удалось] - Завершение работы скрипта...${reset}" ; echo -en "\n"
    fi
    sleep 1
    exit 0
}


function print_help() {
    echo -en "\n"
    echo "  ${yellow}Справка по работе скрипта $ME из командной строки${reset}"
    echo -en "\n"
    echo "    Использование: $ME [-i] [-u] [-r] [-n] [-f] [-d] [-h] "
    echo -en "\n"
    echo "        Параметры:"
    echo "            -i / -I        Установка Homebridge на чистой системе."
    echo "            -u / -U        Полное удаление Homebridge с очисткой системы."
    echo "            -r / -R        Установка Homebridge с полным удалением старой версии."
    echo "            -n / -N        Полное удаление Node.js и его хвостов из системы."
    echo "            -f / -F        Обновление Homebridge до актуальной версии в тихом режиме."
    echo "            -d / -D        Самоудаление папки со скриптом установки."
    echo -en "\n"
    echo "            -h / -H        Вызов справки."
    echo -en "\n"
    exit 0
}


# Если аргументов нет — запускаем интерактивное меню
if [ $# = 0 ]; then
    GoToMenu
fi

while getopts ":iIuUrRdDhHnNfF" Option
do
    case $Option in
        i|I)    cmdkey=1 ; InstallScript ;;
        u|U)    cmdkey=1 ; UninstallScript ;;
        r|R)    cmdkey=1 ; UninstallScript ; InstallScript ;;
        n|N)    cmdkey=1 ; UninstallNodeJS ;;
        f|F)    cmdkey=1 ; UpdatingScript ;;
        d|D)    RremovalItself ;;
        h|H)    print_help ;;
        *)      echo -en "\n" ; echo -en "\n"
                echo "${red}           Неправильный параметр!${reset}"
                print_help
                exit 1
                ;;
    esac
done

shift $(($OPTIND - 1))
exit 0

# Info
# https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-Raspbian
# https://github.com/homebridge/homebridge-config-ui-x/wiki/Homebridge-Service-Command
# https://github.com/homebridge/homebridge-raspbian-image/wiki#default-ports
