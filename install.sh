#!/bin/bash
#-x
clear




#Шаблоны для вывода информации
red=$(tput setf 4)
green=$(tput setf 2)
reset=$(tput sgr0)
#Ключ запуска командной строки
cmdkey=0
UninstallScriptSettings=0
# Автоопределение названия запускаемого скрипта
ME=`basename $0`
clear



cd ~
function Zagolovok {
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                   Установка HomeBridge и его зависимостей.                  ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
}
function GoToMenu {
  GoToMenuInfo="Чтобы продолжить, введите"
while :
	do
	clear
	Zagolovok 
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
	echo "           0 - Завершение работы с самоудалением скрипта"
	echo -en "\n"
	echo "     │                                                                   │"
	echo "     └────────────────────────────────────────────── H - Вызов справки ──┘"
	echo -en "\n"
	echo -e "\a"
	echo "           $GoToMenuInfo номер пункта и нажмите на Enter"
	echo -e "\a"
	read item
	printf "\n"
	case "$item" in

		0) 	RremovalItself ;;

		1) 	ReinstallInfo="" ; InstallScript ;;

		2) 	cmdkey=1 ; UninstallScript ; cmdkey=0 ; InstallScript ;;

		3) 	ReinstallInfo="" ; UninstallScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	clear && GoToMenuInfo="Попробуйте еще раз ввести" ;;

	esac
done
}
        
function ExitOrContinue() {
  echo -en "\n"
if [ $cmdkey -eq 2 ]; then
        echo -e "\a"
        read -p "${green}           Нажмите любую клавишу, что бы установить HomeBridge...${reset}"
	cmdkey=0
	ReinstallInfo="${green}[OK]${reset}"
        InstallScript
elif [ $cmdkey -eq 3 ]; then
        echo -e "\a"
	cmdkey=1
        InstallScript
else
        read -p "${red}           Что то пошло не так...${reset}"
fi
}





function СheckingInstalledPackage() {
echo -en "\n" ; echo "  # # Проверка на ранее установленную версию..."
if dpkg -l homebridge &>/dev/null; then
	echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge как системный пакет..."
	InstallInfo="${green}[уже установлен]${reset}"
	InstalledPackageKey=1
elif dpkg -l nodejs &>/dev/null; then
	if npm list -g | grep -q homebridge; then
		echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge из NPM..."
		InstallInfo="${green}[уже установлен]${reset}"
		InstalledPackageKey=1
	else
		echo -en "\n" ; echo "     - В системе уже установлен пакет Node.js ${green}$(node -v | tr -d ' ')${reset}, но HomeBridge не установлен..."
		InstallInfo="${red}[установлен NodeJS]${reset}"
		InstalledPackageKey=1
	fi
fi
echo "InstalledPackageKey = $InstalledPackageKey"
if [ $InstalledPackageKey -eq 1 ]; then
	echo -en "\n" ; echo -e "\a"
	read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
	GoToMenu
else
	echo -en "\n" ; echo -e "\a"
	read -p "${green}           Нажмите любую клавишу, чтобы завершить работу скрипта...${reset}"
	exit 0
fi
}





function BackUpScript() {
if ! [ -d ~/HB_BackUp/ ]; then
		sudo mkdir -p ~/HB_BackUp && sudo chmod 777 ~/HB_BackUp
fi

	if [ -f ~/.homebridge/config.json ]; then
		CheckBackUp=1
		sudo cp -f ~/.homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
	fi
	if [ -f /var/lib/homebridge/config.json ]; then
		CheckBackUp=1
		sudo cp -f /var/lib/homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
	fi
	if [ -f /var/homebridge/config.json ]; then
		CheckBackUp=1
		sudo cp -f /var/homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
	fi
	if [ -f /var/lib/homebridge/backups/config-backups/config.json.* ]; then
		CheckBackUp=1
		sudo cp -f /var/lib/homebridge/backups/config-backups/config.json.* ~/HB_BackUp/
	fi

if [ $CheckBackUp -eq 1 ]; then
	echo -en "\n" ; echo "  # # Создание резервной копии конфигурационных файлов HomeBridge..."
fi	
}




function InstallScript() {
clear
Zagolovok
СheckingInstalledPackage
BackUpScript

echo -en "\n" ; echo "  # # Добавление репозитория HomeBridge..."
curl -sSfL https://repo.homebridge.io/KEY.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/homebridge.gpg  > /dev/null
echo "deb [signed-by=/usr/share/keyrings/homebridge.gpg] https://repo.homebridge.io stable main" | sudo tee /etc/apt/sources.list.d/homebridge.list > /dev/null

echo -en "\n" ; echo "  # # Добавление репозитория Node.js..."
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - > /dev/null 2>&1

echo -en "\n" ; echo "  # # Обновление кеша данных и индексов репозиторий..."
sudo rm -Rf /var/lib/apt/lists
sudo apt update -y > /dev/null 2>&1
sudo apt upgrade -y > /dev/null 2>&1

#echo -en "\n" ; echo "  # # Установка необходимых зависимостей"
#echo -en "\n" ; echo "  # # Устранение ранее известных проблем..."

echo -en "\n" ; echo "  # # Установка пакетов gcc g++ make python..."
sudo apt-get install -y gcc g++ make python > /dev/null

echo -en "\n" ; echo "  # # Установка пакета libavahi-compat-libdnssd-dev..."
sudo apt-get install -y libavahi-compat-libdnssd-dev > /dev/null

echo -en "\n" ; echo "  # # Установка Node.js..."
sudo apt-get install -y nodejs > /dev/null 2>&1

echo -en "\n" ; echo "  # # Установка HomeBridge..."
sudo apt-get install homebridge -y > /dev/null 2>&1

if [ -f ~/HB_BackUp/config.json.* ]; then
	if ! [ -d /var/lib/homebridge/backups/config-backups/ ]; then
		sudo mkdir -p /var/lib/homebridge/backups/config-backups/ && sudo chmod 777 /var/lib/homebridge/backups/config-backups/
	fi
	echo -en "\n" ; echo "  # # Восстанавление резервной копии конфигурационного файла HomeBridge..."
	sudo mv -f ~/HB_BackUp/config.json.* /var/lib/homebridge/backups/config-backups/
	sudo rm -rf ~/HB_BackUp
fi

echo -en "\n"
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║              ${green}Установки HomeBridge и его зависимостей завершена${reset}              ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
echo "    ┌──────────── Полезная информация для работы с HomeBridge ────────────┐"
echo "    │                                                                     │"
echo "    │                    Доступ к HomeBridge по адресу                    │"
echo "    │                      ${green}http://$(hostname -I | tr -d ' '):8581/${reset}                      │"
echo "    │                                                                     │"
echo "    │                      Войти в Homebridge Shell                       │"
echo "    │                            ${green}sudo hb-shell${reset}                            │"
echo "    │                                                                     │"
echo "    │                  Редактирование файла конфигурации                  │"
echo "    │              ${green}sudo nano /var/lib/homebridge/config.json${reset}              │"
echo "    │                                                                     │"
echo "    │                  Путь хранения - ${green}/var/lib/homebridge${reset}                │"
echo "    │                   Путь плагина - ${green}/var/lib/homebridge/node_modules${reset}   │"
echo "    │                      Узел Путь - ${green}/opt/homebridge/bin/node${reset}           │"
echo "    │                                                                     │"
echo "    │                Перезагрузка HB - ${green}sudo hb-service restart${reset}            │"
echo "    │                  Остановить HB - ${green}sudo hb-service stop${reset}               │"
echo "    │                    Запустит HB - ${green}sudo hb-service start${reset}              │"
echo "    │                                                                     │"
echo "    │              Просмотр журналов - ${green}sudo hb-service logs${reset}               │"
echo "    │                                                                     │"
echo "    │                    Установка и удаление плагинов                    │"
echo "    │               ${green}sudo hb-service add homebridge-example${reset}                │"
echo "    │               ${green}sudo hb-service remove homebridge-example${reset}             │"
echo "    │                                                                     │"
echo "    └─────────────────────────────────────────────────────────────────────┘"
echo "                                 ┌ Установленная версия Node.js ┐"
echo "                                 │           ${green}$(node -v | tr -d ' ')${reset}           │"
echo "                                 └──────────────────────────────┘"
echo -e "\a"

InstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function UninstallScript() {
clear
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║      Удаление Homebridge, а так же всех его плагинов с конфигурациями       ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"

echo -en "\n" ; echo "  # # Остановка и завершение процесса Homebridge..."
sudo hb-service stop > /dev/null 2>&1
sudo systemctl stop homebridge > /dev/null 2>&1
sudo service homebridge stop > /dev/null 2>&1
sudo pm2 stop all > /dev/null 2>&1
sudo killall -w -s 9 -u homebridge > /dev/null 2>&1

BackUpScript

echo -en "\n" ; echo "  # # Деинсталляция HomeBridge..."
sudo apt-get remove homebridge -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Деинсталляция NodeJS..."
sudo apt-get purge --auto-remove nodejs -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление репозитория Homebridge..."
sudo rm -rf /etc/apt/sources.list.d/homebridge.list

echo -en "\n" ; echo "  # # Удаление репозитория NodeJS..."
sudo rm -rf /etc/apt/sources.list.d/chris-lea-node_js-*

echo -en "\n" ; echo "  # # Деинсталляция всех плагинов и конфигурацию Homebridge..."
sudo apt-get purge homebridge -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление пользователя homebridge..."
sudo userdel -rf homebridge > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление служб из списока автозагрузки..."
sudo update-rc.d homebridge remove > /dev/null 2>&1
sudo rm -rf /etc/init.d/homebridge
sudo rm -rf /etc/systemd/system/homebridge*
sudo rm -rf /etc/systemd/system/multi-user.target.wants/homebridge*
sudo systemctl --system daemon-reload > /dev/null

echo -en "\n" ; echo "  # # Удаление хвостов, для возможности последующей нормальной установки..."
sudo curl -sfL https://gist.githubusercontent.com/oznu/312b54364616082c3c1e0b6b02351f0e/raw/remove-node.sh | sudo bash > /dev/null 2>&1
sudo rm -rf /usr/lib/node_modules/homebridge*
sudo rm -rf /usr/bin/homebridge*
sudo rm -rf /etc/default/homebridge*
sudo rm -rf /var/lib/homebridge*
sudo rm -rf /home/pi/.homebridge*
sudo rm -rf /home/homebridge*
sudo rm -rf ~/.homebridge*

echo -en "\n" ; echo "  # # Удаление хвостов от плагинов..."
sudo rm -rf /usr/bin/ps4-waker
sudo rm -rf /usr/lib/node_modules/ps4-waker



echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "   ${green}Удаление Homebridge, а так же всех его плагинов с конфигурациями завершено${reset}"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

UninstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function RremovalItself() {
clear
echo -en "\n"
echo "                   Самоудаление папки со скриптом установки..."
cd
sudo rm -rf ~/HomebBridge-Install-Script

if [ $? -eq 0 ]; then
	echo -n "${green}${toend}[OK]"
else
	echo -n "${red}${toend}[fail]"
fi

echo -n "${reset}"
echo
echo -en "\n" ; echo "${red}               - Завершение работы скрипта...${reset}" ; echo -en "\n"
sleep 1
exit 0
}



function print_help() {
	echo -en "\n"
	echo "  Справка по работе скрипта $ME из командной строки"
	echo -en "\n"
	echo "    Использование: $ME [-i] [-u] [-r] [-d] [-h] "
	echo -en "\n"
	echo "        Параметры:"
	echo "            -i        Установка Homebridge на чистой системе."
	echo "            -u        Полное удаление Homebridge с очисткой системы."
	echo "            -r        Установка Homebridge с полным удалением старой версии."
	echo "            -d        Самоудаление папки со скриптом установки."
	echo -en "\n"
	echo "            -h        Вызов справки."
	echo -en "\n"
exit 0
}





# Если скрипт запущен без аргументов, открываем справку.
if [ $# = 0 ]; then
	GoToMenu
fi

while getopts ":uUiIrRhHdD" Option
	do

	cmdkey=1
 
	case $Option in

		I|i) 	InstallScript ;;

		U|u) 	UninstallScript ;;

		R|r) 	UninstallScript ; InstallScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	echo -en "\n" ; echo -en "\n"
			echo "${red}           Неправильный параметр!${reset}"
			print_help ; exit 1 ;;
	esac
done

shift $(($OPTIND - 1))

exit 0
