# ikev2-server-mikrotik
Scripts for auto-configuration ikev2-ipsec-server for Routeros v7

Данные скрипты предназначены для автоматизации установки и создания конфигураций IPSec для Mikrotik.

Для того чтобы их запустить надо всего 2 команды на самом микротике.

Мастер скрипт содержит в себе все пять рабочих скриптов и предназначем для импорта в микротик.

These scripts are designed to automate the installation and creation of IPSec configurations for Mikrotik.

In order to run them, you need only 2 commands on the Mikrotik itself.


The master script contains all five working scripts and is intended for import into Mikrotik.

```
/tool fetch url "https://raw.githubusercontent.com/aeternuspolyphagus/ikev2-server-mikrotik/main/master.rsc" mode=https dst-file=master.rsc

import file-name=master.rsc
```