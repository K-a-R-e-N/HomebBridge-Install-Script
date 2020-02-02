echo 
echo Удаление Home Bridge и его хвостов
echo 
echo.
echo Начало
sudo killall homebridge
sudo userdel -r homebridge
sudo npm uninstall -g homebridge
sudo apt-get purge --auto-remove nodejs -y </dev/null
sudo apt-get purge --auto-remove libavahi-compat-libdnssd-de -y </dev/null
sudo rm -rf /usr/lib/node_modules/homebridge*
sudo rm -rf /etc/systemd/system/homebridge
sudo rm -rf /etc/default/homebridge*
sudo rm -rf /home/pi/.homebridge*
sudo rm -rf /var/lib/homebridge*
sudo rm -rf ~/.homebridge*
sudo rm -rf /usr/bin/ps4-waker
sudo rm -rf /usr/lib/node_modules/ps4-waker
echo Процесс удаления Home Bridge и его хвостов, завершен !
