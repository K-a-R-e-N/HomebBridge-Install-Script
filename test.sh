#!/bin/bash
#set -x
cd ~
clear

function Zagolovok {
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                   Установка HomeBridge и его зависимостей                   ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
}

# Изменение строки приветствия
PS3='Выберите операционную систему: '

select OS in "Linux" "Windows" "Mac OS" "BolgenOS"
do
  echo
  echo "Вы выбрали $OS!"
  echo
  break
done

















red=$(tput setf 4)
green=$(tput setf 2)
reset=$(tput sgr0)
toend=$(tput hpa $(tput cols))$(tput cub 6)

echo -e "Удаляется файл..."

# Команда, которую нужно отследить
rm test_file

if [ $? -eq 0 ]; then
    echo -n "${green}${toend}[OK]"
else
    echo -n "${red}${toend}[fail]"
fi
echo -n "${reset}"

  echo -en "\n"
  echo "        ┌─ Выберите действие: ────────────────────────────────────────┐"
  echo "        │                                                             │"
  echo "        │       1 - Предварительно очистить систему                   │"
  echo "        │       2 - Продолжить без очистки системы (Для опытных)      │"
  echo "        │       3 - Завершить работу скрипта                          │"
  echo "        │                                                             │"
  echo "        └─────────────────────────────────────────────────────────────┘"
  echo "           Чтобы продолжить, введите номер пункта и нажмите на Enter"
  echo -e "\a"

read item
case "$item" in
    y|Y) echo "Ввели «y», продолжаем..."
        ;;
    n|N) echo "Ввели «n», завершаем..."
        exit 0
        ;;
    *) echo "Ничего не ввели. Выполняем действие по умолчанию..."
        ;;
esac
