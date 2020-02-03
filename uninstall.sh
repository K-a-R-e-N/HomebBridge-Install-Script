#!/bin/bash

echo -en '\n'
echo ' ========================================================'
echo '            Удаление Home Bridge и его хвостов'
echo ' ========================================================'
echo -en '\n'
echo '   Убиваем процесс...'
sudo killall homebridge > /dev/null 2>&1
echo '   Деинсталируем Home Bridge...'
sudo npm uninstall -g homebridge > /dev/null 2>&1
echo '   Удаляем пользователя homebridge...'
sudo userdel -rf homebridge > /dev/null 2>&1
echo '   Деинсталируем nodejs...'
sudo apt-get purge --auto-remove nodejs -y > /dev/null 2>&1
echo -en '\n'
echo '   Очишаем хвосты:'
echo '       по пути /usr/lib/node_modules/homebridge*'
sudo rm -rf /usr/lib/node_modules/homebridge*
echo '       по пути /usr/bin/homebridge'
sudo rm -rf /usr/bin/homebridge*
echo '       по пути /etc/systemd/system/homebridge*'
sudo rm -rf /etc/systemd/system/homebridge*
echo '       по пути /etc/systemd/system/multi-user.target.wants/homebridge*'
sudo rm -rf /etc/systemd/system/multi-user.target.wants/homebridge*
echo '       по пути /etc/default/homebridge*'
sudo rm -rf /etc/default/homebridge*
echo '       по пути /var/lib/homebridge*'
sudo rm -rf /var/lib/homebridge*
echo '       по пути /home/pi/.homebridge*'
sudo rm -rf /home/pi/.homebridge*
echo '       по пути /home/homebridge*'
sudo rm -rf /home/homebridge*
echo '       по пути ~/.homebridge*'
sudo rm -rf ~/.homebridge*
echo -en '\n'
echo '   Очищаем хвосты от плагинов:'
echo '       Плагин ps4-waker'
sudo rm -rf /usr/bin/ps4-waker
sudo rm -rf /usr/lib/node_modules/ps4-waker
echo -en '\n'
echo ' ========================================================'
echo '  Процесс удаления Home Bridge и его хвостов, завершен !'
echo ' ========================================================'
echo -en '\n'
echo -en '\n'
echo '       Самоудаляем папку со скриптом установки...'
cd ..	
sudo rm -rf HomebBridge-Install-Script
echo -en '\n'
