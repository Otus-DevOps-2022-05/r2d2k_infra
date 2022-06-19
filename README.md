# r2d2k_infra
r2d2k Infra repository

## Bastion host homework (SSH)
**Задание №1:** Исследовать способ подключения к `someinternalhost` в одну команду из вашего рабочего устройства, проверить работоспособность найденного решения

**Решение №1:** Использовать ключ `ssh -J`, который позволяет прокладывать подключение через один или несколько промежуточных хостов.

**Результат №1:**
```
localuser@localhost:~$ ssh -i ~/.ssh/appuser -J appuser@bastion_ext_ip appuser@someinternalhost_int_ip

Welcome to Ubuntu 15.10 (GNU/Linux 4.2.0-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Wen Oct 21 07:28:00 2015 from 0.0.0.0
appuser@someinternalhost:~$
```


**Задание №2:** Предложить вариант решения для подключения из консоли при помощи команды вида `ssh someinternalhost` из локальной консоли рабочего устройства, чтобы подключение выполнялось по алиасу `someinternalhost`.

**Решение №2:** Настроить alias в локальном конфиге ssh
```
localuser@localhost:~$ cat ~/.ssh/config

Host someinternalhost
    HostName someinternalhost_int_ip
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyJump appuser@bastion_ext_ip
```

**Результат №2:**
```
localuser@localhost:~$ ssh someinternalhost

Welcome to Ubuntu 15.10 (GNU/Linux 4.2.0-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Wen Oct 21 07:28:00 2015 from 0.0.0.0
appuser@someinternalhost:~$
```

## Bastion host homework (OpenVPN)

Данные для проверки VPN сервера:
```
bastion_IP = 51.250.95.231
someinternalhost_IP = 10.128.0.19
```
