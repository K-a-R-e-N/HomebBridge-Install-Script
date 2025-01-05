#!/bin/bash
yellow=$(tput setf 6) ; red=$(tput setf 4) ; green=$(tput setf 2) ; reset=$(tput sgr0)
cmdkey=0 ; ME=`basename $0` cd~ ; clear

BackupsFolder=~/HB_Backup


function Zagolovok {
echo -en "${yellow} \n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                   $ZI HomeBridge и его зависимостей.                  ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n ${reset}"
}
function GoToMenu {
  GoToMenuInfo="Чтобы продолжить, введите"
while :
	do
	clear ; CheckBackUp=0 ; BackupRecovery=0
	ZI=Установка && Zagolovok 
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
	echo "           4 - Обновление Homebridge до актуально версии $UpdatingInfo"
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

		4) 	UpdatingInfo="" ; UpdatingScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	clear && GoToMenuInfo="Попробуйте еще раз ввести" ;;

	esac
done
}




function СheckingInstalledPackage() {
InstalledPackageKey=0 ; echo -en "\n" ; echo "  # # Проверка на ранее установленную версию..."
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

if [ $InstalledPackageKey -eq 1 ]; then
	if [ $cmdkey -eq 1 ]; then
		echo -en "\n" ; echo -e "\a"
		read -p "${green}           Нажмите любую клавишу, чтобы завершить работу скрипта...${reset}"
		exit 0
	else
		echo -en "\n" ; echo -e "\a"
		read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
		GoToMenu
	fi
fi
}





function BackUpScript() {

[ ! -d $BackupsFolder ] && sudo mkdir -p $BackupsFolder && sudo chmod 777 $BackupsFolder

	HA_SOURCE=/var/lib/homebridge/backups/config-backups
	[ ! -f $HA_SOURCE/config.json.* ] && CheckBackUp=1 && sudo cp -f $HA_SOURCE/config.json.* $BackupsFolder >/dev/null 2>&1

	HA_SOURCE=/var/homebridge
	[ ! -f $HA_SOURCE/config.json ] && CheckBackUp=1 && sudo cp -f $HA_SOURCE/config.json $BackupsFolder/config.json.$(date +%s)000 >/dev/null 2>&1

	HA_SOURCE=/var/homebridge
	[ ! -f $HA_SOURCE/config.json ] && CheckBackUp=1 && sudo cp -f $HA_SOURCE/config.json $BackupsFolder/config.json.$(date +%s)000 >/dev/null 2>&1

	HA_SOURCE=~/.homebridge
	[ ! -f $HA_SOURCE/config.json ] && CheckBackUp=1 && sudo cp -f $HA_SOURCE/config.json $BackupsFolder/config.json.$(date +%s)000 >/dev/null 2>&1

if [ $CheckBackUp -eq 1 ]; then
	echo -en "\n" ; echo "  # # Создание резервной копии конфигурационных файлов HomeBridge..."
fi
}




function InstallScript() {
clear ; CheckBackUp=0 ; BackupRecovery=0
ZI="Установка" && Zagolovok
СheckingInstalledPackage
BackUpScript

echo -en "\n" ; echo "  # # Добавление репозитория HomeBridge..."
curl -sSfL https://repo.homebridge.io/KEY.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/homebridge.gpg  > /dev/null
echo "deb [signed-by=/usr/share/keyrings/homebridge.gpg] https://repo.homebridge.io stable main" | sudo tee /etc/apt/sources.list.d/homebridge.list > /dev/null

echo -en "\n" ; echo "  # # Добавление репозитория Node.js..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - > /dev/null 2>&1

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

echo -en "\n" ; echo "  # # Установка порта HomeBridge по умолчанию на 8080..."
sudo hb-service install --port 8080
#sudo sed -i 's|listen 80;  |listen 8080;|' /etc/nginx/sites-available/homebridge.local
#sudo sed -i 's|:80;  |:8080;|' /etc/nginx/sites-available/homebridge.local
#sudo sed -i 's|127.0.0.1:8581;|127.0.0.1:8080;|' /etc/nginx/sites-available/homebridge.local
#sudo sed -i 's|"port": 8581|"port": 8080|' /var/lib/homebridge/config.json
sudo systemctl restart nginx > /dev/null 2>&1

# Восстанавление резервной копии
if [ -f $BackupsFolder/config.json.* ]; then
	BackupRecovery=1 && echo -en "\n" && echo "  # # Восстанавление резервной копии конфигурационных файлов HomeBridge..."

	if [ ! -d /var/lib/homebridge/backups/config-backups ] ; then 
		sudo mkdir -p /var/lib/homebridge/backups/config-backups && sudo chmod 777 /var/lib/homebridge/backups/config-backup
	fi
	sudo mv -f $BackupsFolder/config.json.* /var/lib/homebridge/backups/config-backups
	sudo rm -rf $BackupsFolder
fi

echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║              ${green}Установки HomeBridge и его зависимостей завершена${reset}              ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
echo "    ┌──────────── Полезная информация для работы с HomeBridge ────────────┐"
echo "    │                                                                     │"
echo "    │                    Доступ к HomeBridge по адресу                    │"
echo "    │                      ${green}http://$(hostname -I | tr -d ' '):8080/${reset}                      │"
echo "    │                                                                     │"
echo "    │                  Редактирование файла конфигурации                  │"
echo "    │              ${green}sudo nano /var/lib/homebridge/config.json${reset}              │"
echo "    │                                                                     │"
if [ $CheckBackUp -eq 1 ]; then
echo "    │               Путь к восстанавленым резервным копиям:               │"
echo "    │             ${green}/var/lib/homebridge/backups/config-backups/${reset}              │"
echo "    │                                                                     │"
fi
echo "    │               Путь хранения - ${green}/var/lib/homebridge${reset}                   │"
echo "    │                Путь плагина - ${green}/var/lib/homebridge/node_modules${reset}      │"
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
echo "                                 │           ${green}$(node -v | tr -d ' ')${reset}           │"
echo "                                 └──────────────────────────────┘"
echo -e "\a"

InstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function UninstallScript() {
clear ; CheckBackUp=0 ; BackupRecovery=0
ZI=" Удаление" && Zagolovok

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
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "   ${green}Удаление Homebridge, а так же всех его плагинов с конфигурациями завершена${reset}"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

UninstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function UpdatingScript() {
clear ; CheckBackUp=0 ; BackupRecovery=0
ZI=" Обновление" && Zagolovok

BackUpScript

echo -en "\n" ; echo "  # # Обновление кеша данных и индексов репозиторий..."
sudo rm -Rf /var/lib/apt/lists
sudo apt update -y > /dev/null 2>&1
sudo apt-get update -y > /dev/null 2>&1
sudo apt upgrade -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Обновление HomeBridge..."
sudo apt-get install homebridge -y > /dev/null 2>&1

echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "   ${green}Обновление Homebridge, а так же всех его плагинов с конфигурациями завершена${reset}"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

UpdatingInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function RremovalItself() {
echo -en "\n" ; echo "                   Самоудаление папки со скриптом установки...  " ; cd
sudo rm -rf ~/HomebBridge-Install-Script
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
