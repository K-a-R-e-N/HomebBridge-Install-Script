#!/bin/bash
#-x




#Шаблоны для вывода информации
red=$(tput setf 4)
green=$(tput setf 2)
reset=$(tput sgr0)
#Ключ запуска командной строки
cmdkey=0
UninstallScriptSettings=0
# Автоопределение названия запускаемого скрипта
ME=`basename $0`




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
  echo "           2 - Установка Homebridge с полным удалением старой версии $ReinstallInfo"
  echo "           3 - Полное удаление Homebridge с очисткой системы $UninstallInfo"
  echo -en "\n"
  echo "           D -  Самоудаление папки со скриптом установки
  echo -en "\n"
  echo "            0 - Завершить работу скрипта"
  echo -en "\n"
  echo "     │                                                                   │"
  echo "     └────────────────────────────────────────────── H - Вызов справки ──┘"
  echo -en "\n"
  echo "           $GoToMenuInfo номер пункта и нажмите на Enter"
  echo -e "\a"
  read item
  printf "\n"
  case "$item" in
  0)    clear
        echo -en "\n" ; echo "${red}               - Завершение работы скрипта...${reset}" ; echo -en "\n"
        sleep 2
        clear
        exit 0
      ;;
  1)    InstallScript
      ;;
  2)    UninstallScript
        InstallScript
	ReinstallInfo="${green}[OK]${reset}"
      ;;
  3)    UninstallScript
      ;;
  H|h)  print_help
      ;;
  *)     clear && GoToMenuInfo="Попробуйте еще раз ввести"
      ;;
esac
done
}

