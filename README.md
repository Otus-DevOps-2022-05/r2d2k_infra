# r2d2k_infra
r2d2k Infra repository

## Bastion host homework
Задание: Исследовать способ подключения к someinternalhost в одну команду из вашего рабочего устройства, проверить работоспособность найденного решения и внести его в README.md в вашем репозитории

Решение: Использовать ключ -J ssh, который позволяет прокладывать подключение через одмн или несколько промежуточных хостов.

Команда
```console
localuser@localhost~$ ssh -i ~/.ssh/appuser -J appuser@bastion_ext_ip appuser@someinternalhost
```
Результат
```console
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Sun Jun 19 14:52:35 2022 from 0.0.0.0
appuser@someinternalhost:~$
```
