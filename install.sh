#!/bin/bash

echo -en '\n'
echo '========================================='
echo ' Установка Home Bridge и его зависимостей'
echo '========================================='
echo -en '\n'
echo '# # Установка репозитория для Node.js 12.x...'
curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -> /dev/null 2>&1
echo -en '\n'
