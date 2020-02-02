#!/bin/bash

echo -en '\n'
echo =========================================
echo Установка Home Bridge и его зависимостей
echo =========================================
echo -en '\n'
echo # # Установка репозитория для Node.js 12.x...
curl -sL https://deb.nodesource.com/setup_12.x | sudo bash - > /dev/null 2>&1
echo -en '\n'
echo # # Установка пакетов nodejs gcc g++ make python...
sudo apt-get install -y nodejs gcc g++ make python > /dev/null 2>&1
echo Версия установленой NodeJS: && sudo node -vecho
echo -en '\n'
