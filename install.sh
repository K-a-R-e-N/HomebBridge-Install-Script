#!/bin/bash
#set -x
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
function GoToMenu {
  while :
  do
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
  read key
  printf "\n"
  case $key in
  1)     echo "                     - Предварительная очистка системы..." && sleep 2 && clear && bash uninstall.sh && Zagolovok
                                            echo -en "\n" ; echo "  # # Test..."
                                            if [ -f ~/.homebridge/config.json ]; then
                                            echo -en "\n" ; echo "  # # Создание резервной копии конфигурационного файла HomeBridge..."
                                            sudo mkdir -p ~/HB_BackUp && sudo chmod 777 ~/HB_BackUp
                                            sudo cp -f ~/.homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
                                            if [ -f /var/lib/homebridge/config.json ]; then
                                            echo -en "\n" ; echo "  # # Создание резервной копии конфигурационного файла HomeBridge..."
                                            sudo mkdir -p ~/HB_BackUp && sudo chmod 777 ~/HB_BackUp
                                            sudo cp -f /var/lib/homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
                                            
                                            echo -en "\n" ; echo "  # # Test2..."
                                            return;;
  2)     echo "                  - Выполнение скрипта без очистки системы..." && sleep 2 && clear && Zagolovok
                                            if [ -f ~/.homebridge/config.json ]; then
                                            echo -en "\n" ; echo "  # # Создание резервной копии конфигурационного файла HomeBridge..."
                                            sudo mkdir -p ~/HB_BackUp && sudo chmod 777 ~/HB_BackUp
                                            sudo cp -f ~/.homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
                                            if [ -f /var/lib/homebridge/config.json ]; then
                                            echo -en "\n" ; echo "  # # Создание резервной копии конфигурационного файла HomeBridge..."
                                            sudo mkdir -p ~/HB_BackUp && sudo chmod 777 ~/HB_BackUp
                                            sudo cp -f /var/lib/homebridge/config.json ~/HB_BackUp/config.json.$(date +%s)000
                                            fi
                                            return;;
  3)     echo "               - Завершение работы скрипта..." && exit 0;;
  *)     echo "                           Попробуйте еще раз.";;
  esac
  done
}

Zagolovok

echo -en "\n" ; echo "  # # Проверка на ранее установленную версию..."
if dpkg -l homebridge &>/dev/null; then
  echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge как системный пакет..."
  GoToMenu
elif dpkg -l nodejs &>/dev/null; then
  if npm list -g | grep -q homebridge; then
  echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge из NPM..."
  GoToMenu
  else
  echo -en "\n" ; echo "     - В системе уже установлен пакет NodeJS $(nodejs -v), но HomeBridge не установлен..."
  GoToMenu
  fi
else
  echo "     - Ранее установленых пакетов не обнаружено..."
fi

#echo -en "\n" ; echo "  # # Установка необходимых зависимостей"

echo -en "\n" ; echo "  # # Установка Node.js..."
echo "     - Добавление ключа подписи пакета NodeSource..."
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key --quiet add -
echo "     - Добавление репозитория NodeSource..."
NODE_VERSION=node_12.x && DISTRO="$(lsb_release -s -c)"
echo "deb https://deb.nodesource.com/$NODE_VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "deb-src https://deb.nodesource.com/$NODE_VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "     - Обновление списка пакетов и установка Node.js..."
sudo apt-get update > /dev/null && sudo apt-get install -y nodejs > /dev/null

echo -en "\n" ; echo "  # # Установка пакетов gcc g++ make python..."
sudo apt-get install -y gcc g++ make python > /dev/null

echo -en "\n" ; echo "  # # Установка пакета libavahi-compat-libdnssd-dev..."
sudo apt-get install -y libavahi-compat-libdnssd-dev > /dev/null

echo -en "\n" ; echo "  # # Обновление npm (version 6.13.4 has issues with git dependencies)..."
sudo npm install -g npm > /dev/null

echo -en "\n" ; echo "  # # Устранение ранее известных проблем..."
#sudo npm cache clean --force > /dev/null
#sudo npm install
sudo npm cache verify > /dev/null

echo -en "\n" ; echo "  # # Установка HomeBridge..."
sudo npm install -g --unsafe-perm homebridge > /dev/null

echo -en "\n" ; echo "  # # Установка интерфейса для HomeBridge..."
sudo npm install -g --unsafe-perm homebridge-config-ui-x > /dev/null

echo -en "\n" ; echo "  # # Создание основного пользователя для HomeBridge..."
echo -en "\n" ; echo "  # # Добавление полномочия по управлению через интерфейс..."
echo -en "\n" ; echo "  # # Создание основного каталога HomeBridge..."
echo -en "\n" ; echo "  # # Создание конфигурационного файла HomeBridge..."
echo -en "\n" ; echo "  # # Создание служб автозапуска..."
echo -en "\n" ; echo "  # # Создаем файл настроек HomeBridge..."
echo -en "\n" ; echo "  # # Добавление служб в список автозагрузки и их запуск..."
sudo hb-service install --port 8080 --user homebridge &>/dev/null

if [ -d ~/HB_BackUp/ ]; then 
echo -en "\n" ; echo "  # # Восстанавление резервной копии конфигурационного файла HomeBridge..."
sudo mv -f ~/HB_BackUp/config.json.* /var/lib/homebridge/
sudo rm -rf ~/HB_BackUp
fi
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║          Процесс установки HomeBridge и его зависимостей завершен!          ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
echo "    ┌──────────── Полезная информация для работы с HomeBridge ────────────┐"
echo "    │                                                                     │"
echo "    │                    Доступ к HomeBridge по адресу                    │"
echo "    │                      http://$(hostname -I | tr -d ' '):8080/                      │"
echo "    │                                                                     │"
echo "    │                       Логин и пароль для входа                      │"
echo "    │                            admin / admin                            │"
echo "    │                                                                     │"
echo "    │                  Редактирование файла конфигурации                  │"
echo "    │              sudo nano /var/lib/homebridge/config.json              │"
echo "    │                                                                     │"
echo "    │                     Перезагрузка Home Assistant                     │"
echo "    │                       sudo hb-service restart                       │"
echo "    │                                                                     │"
echo "    │                          Просмотр журналов                          │"
echo "    │                         sudo hb-service logs                        │"
echo "    │                                                                     │"
echo "    └─────────────────────────────────────────────────────────────────────┘"
echo -en "\n"
