# Скрипт установки новой HomeBridge и Node.js на Raspberry Pi
_HomebBridge Installation Script_##

На сайте уже присутствует аналогичная статья, но изучив его, было выявлено что пакеты которые устанавливает скрипт не являются самой актуальной версией. Собственно было решено сделать собственный скрипт, который будет ставить самые свежие версии HomeBridge и Node.js. Так же в скрипте учтены важные моменты и проделаны специальные настройки, чтобы у вас не возникало ни каких проблем во время установки.



## Реализованные функции
Homebridge Config UI X будет запускаться в режиме Standalone. Это автономный режим пользовательского интерфейса, который будет запускаться как отдельный сервис для HomeBridge. Его основным преимуществом является то, что в случае сбоя Homebridge из-за неправильной конфигурации или по какой-либо другой причине вы все равно сможете получить доступ к пользовательскому интерфейсу для просмотра журналов или восстановления резервной копии конфигурации
Настроены разрешения Homebridge Config UI X для выполнения таких действий, как установка плагинов и перезапуск Homebridge
Учтены и проделаны важные модификации, после которых переустановка HomeBridge, не будут вызывать каких либо  проблем
Реализовано установка дополнительных зависимостей, таких как gcc, g++, make, python
Node.js ставиться последней 12.x версии
Настроенный файл конфигурации уже импортирован
Применены специальные права для правильного взаимодействия с платой Raspberry Pi
Реализовано два отдельных сервиса для автозапуска HomeBridge и Homebridge Config UI X
В конце установки реализовал вывод полезной информации
Реализована возможность полной деинсталляции HomeBridge и его зависимостей
Для актуального состояния скрипта, буду постоянно обновлять и дополнять его.
Более подробные сведения и информацию о новых дополнениях вы можете посмотреть здесь
Прежде чем начать, убедитесь, что на вашей Raspberry Pi установлена последняя версия Raspbian OS и обновлены все пакеты до актуального состояния. Для этого введите следующую команду:
```
sudo rm -Rf /var/lib/apt/lists
sudo apt-get update && sudo apt-get upgrade -y && sudo apt install git -y
#Готово
```
Если в  вашей системе ранее был установлен HomeBrige или Node.js, то прежде чем приступить к установке, надо предварительно очистить систему. Чтобы проделать эту операцию, воспользуйтесь специальным параметром скрипта, который описан ниже.

Для чистой установки на новую систему надо скопировать нижние строки и ввести в консоль терминала:

```
git clone https://github.com/K-a-R-e-N/HomebBridge-Install-Script
cd HomebBridge-Install-Script
bash install.sh && bash stripping.sh && cd ..
#Готово
```
Третья строка: `bash install.sh && bash stripping.sh && cd ..` настраиваемая... Можно как добавлять так и удалять параметры...
Если дописать на начало `bash uninstall.sh &&` - то перед установкой, система будет предварительно очищена от ранее установленных версий. Выглядеть эта команда будет так:
```
git clone https://github.com/K-a-R-e-N/HomebBridge-Install-Script
cd HomebBridge-Install-Script
bash uninstall.sh && bash install.sh && bash stripping.sh && cd ..
#Готово
```
итак...

`bash uninstall.sh &&` - Полная деинсталляция HomeBridge и его зависимостей  
`bash install.sh &&` - Чистая установка HomeBridge и его зависимостей  
`bash stripping.sh &&` - Удаляет временную папку с содержимым, где хранился загружаемый скрипт  

Вот и все! Не забудьте поставить лайк
