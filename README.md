## Скрипт установки HomeBridge и Node.js 16.x на Raspberry Pi
_HomebBridge Installation Script_

Cкрипт, который будет ставить самую свежую версию HomeBridge и Node.js. Так же в скрипте учтены важные моменты и проделаны специальные настройки, чтобы у вас не возникало ни каких проблем во время установки.

![logo](https://sprut.ai/static/media/cache/00/05/83/40/2369/50963/1600x_image.png?1580879891)   

### Реализованные функции
* Homebridge Config UI X будет запускаться в режиме Standalone. Это автономный режим пользовательского интерфейса, который будет запускаться как отдельный сервис для HomeBridge. Его основным преимуществом является то, что в случае сбоя Homebridge из-за неправильной конфигурации или по какой-либо другой причине вы все равно сможете получить доступ к пользовательскому интерфейсу для просмотра журналов или восстановления резервной копии конфигурации
* Настроены разрешения Homebridge Config UI X для выполнения таких действий, как установка плагинов и перезапуск Homebridge
* Учтены и проделаны важные модификации, после которых переустановка HomeBridge, не будут вызывать каких либо  проблем
* Реализовано установка дополнительных зависимостей, таких как gcc, g++, make, libavahi-compat-libdnssd-dev, python
* Реализовано правильная установка Node.js версии 16.x
* Применены специальные права для правильного взаимодействия с платой Raspberry Pi
* Реализована возможность полной деинсталляции HomeBridge и его зависимостей
* Автоматическая проверка ранее установленных версии с выводом вариантов, для дальнейших действий
* Создание резервной копии конфигурационнх файлов HomeBridge при его наличии с дальнейшей возможностью восстановления через соответствующее меню UI X конфигуратора
* В конце установки реализовал вывод полезной информации
* Для актуального состояния скрипта, буду постоянно обновлять и дополнять код

 Прежде чем начать, убедитесь, что на вашей Raspberry Pi установлена последняя версия Raspbian OS и обновлены все пакеты до актуального состояния. Для этого введите следующую команду в консоль терминала:

```
sudo rm -Rf /var/lib/apt/lists
sudo apt update && sudo apt upgrade -y && sudo apt install git -y
#Готово
```

Для запуска в обычном режиме, где будет доступно меню для работы со скриптом, введите следующие команды:
```
git clone https://github.com/K-a-R-e-N/HomebBridge-Install-Script
bash ~/HomebBridge-Install-Script/InstallHB.sh
#Готово
```

Так-же, скрипт поддерживает ключи тихой установки.
Для чистой установки на новую систему в тихом режиме, надо скопировать нижние строки и ввести в консоль терминала:
```
git clone https://github.com/K-a-R-e-N/HomebBridge-Install-Script
bash ~/HomebBridge-Install-Script/InstallHB.sh -i -d
#Готово
```
Во второй строке, можно изменить ключи тихой установки на другие... Если дописать ключ `-u` перед ключем `-i` - то перед установкой, система будет предварительно очищена от ранее установленных версий.
Выглядеть эта команда будет так:
```
git clone https://github.com/K-a-R-e-N/HomebBridge-Install-Script
bash ~/HomebBridge-Install-Script/InstallHB.sh -u -i -d
```
>##### _Если в  вашей системе ранее был установлен HomeBrige или Node.js, то прежде чем приступить к установке, надо предварительно очистить систему._

#### _Ключи тихой установки:_
* `-i` - Установка Homebridge на чистой системе.
* `-u` - Полное удаление Homebridge с очисткой системы.
* `-r` - Установка Homebridge с полным удалением старой версии.
* `-d` - Самоудаление папки со скриптом установки.
* `-h` - Вызов справки.
_Ключ `-r` делает то-же самое что и два ключа `-u`+`-i` запущение вместе_
 
#### _Ключи тихой установки имеют очередность!_
```
InstallHB.sh [-i] [-u] [-r] [-d] [-h]
```
Сначала `-i`, потом `-u`, далее `-r` и т.д `-d` `-h`
>>##### _Если поставить перед ключем `-u` ключ `-i`, то установщик его нормально отработает, но если поставить ключ `-d`, то скрипт сработает с ключа который первее, то есть с `-i`._
