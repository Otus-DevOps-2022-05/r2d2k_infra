# r2d2k_infra
r2d2k Infra repository

## Bastion host homework (SSH)
**Задание №1:** Исследовать способ подключения к `someinternalhost` в одну команду из вашего рабочего устройства, проверить работоспособность найденного решения

**Решение №1:** Использовать ключ `ssh -J`, который позволяет прокладывать подключение через один или несколько промежуточных хостов.

**Результат №1:**
```console
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
```console
localuser@localhost:~$ cat ~/.ssh/config

Host someinternalhost
    HostName someinternalhost_int_ip
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyJump appuser@bastion_ext_ip
```

**Результат №2:**
```console
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


## YC practice
**Задание №1:** При помощи `yc` cоздать VM, установить приложение

**Решение №1:** Все работы выполняем в несколько шагов
1. Создание VM
```console
yc compute instance create \
 --name reddit-app \
 --hostname reddit-app \
 --memory=4 \
 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
 --network-interface subnet-name=subnet-1,nat-ip-version=ipv4 \
 --metadata serial-port-enable=1 \
 --ssh-key ~/.ssh/r2d2k-cloud.pub \
 --zone ru-central1-b
```

2. Установка Ruby (install_ruby.sh)
```bash
#!/bin/sh

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-get install -y ruby-full ruby-bundler build-essential

```

3. Установка MongoDB (install_mongodb.sh)
```bash
#!/bin/sh

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt-get update
sudo apt-get install -y mongodb-org

sudo systemctl enable mongod
sudo systemctl start mongod

```

4. Установка и запуск приложения (deploy.sh)
```bash
#!/bin/sh

sudo apt install -y git
cd ~
git clone -b monolith https://github.com/express42/reddit.git && cd reddit && bundle install
puma -d

```

**Результат №1:**
Машина создана, приложение развёрнуто, ждёт проверки, данные ниже.

_Моя ошибка - пытаться использовать новые версии ПО, но автотесты этого не оценили._
```
testapp_IP = 62.84.121.73
testapp_port = 9292
```

**Задание №2:** При помощи `yc` cоздать VM, установить приложение. Использовать метаданные для автоматизации работы

**Решение №2:** Собираем все скрипты в один, указываем его в метаданных `yc`

Скрипт (deploy_auto.sh)
```bash
#!/bin/sh

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-get install -y ruby-full ruby-bundler build-essential git

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt-get update
sudo apt-get install -y mongodb-org

sudo systemctl enable mongod
sudo systemctl start mongod

sudo mkdir -p /opt/app
cd /opt/app
git clone -b monolith https://github.com/express42/reddit.git && cd reddit && bundle install
puma -d

```

Запуск
```console
yc compute instance create \
 --name reddit-app-auto \
 --hostname reddit-app-auto \
 --memory=4 \
 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
 --network-interface subnet-name=subnet-1,nat-ip-version=ipv4 \
 --metadata serial-port-enable=1 \
 --metadata ssh-keys="user:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCVGwT8xMD1j6jC4I/HLr5ctOdcuramEbS0KJzOtZCnBQrgjvmvaf2DaFpy2yd2NgyJBsD3XZSRicPcnqFpTaEws0bztMncVSiXRpKNLZpiYfYnrqT3AOiXsbt+B8RR9B0DSdnYUliLyGXY/yAOVbA10Wvpuh2R0sswpw/LUkP4/2L2ddDdelOGmC4WhXp9koEstD0ELe90+sUL/fcbWfzMkUpqqLFYwuqzb4gBvjif/WgtBWXfazO5Pc5AW2ZMZK1mZYW/hXffJY/NjhWIkZrHc5b7xwT1VXz6aQddRbKjAw4M988kT/tx523v7RdAbgAJUhM2TC6aOeQ/aJgn4T8463H5QuzAToRVAAioutZFGiedbPAl/dDlBAPZzTezUngSri5YMOwSNO+byKUZi1p5nklmn7DoZ8p14yWTF3xj3B0OqP+rDGfHV66YyPbDRmdaWxjB3wKEIWk+d0rNXZKvHN3UZfBFaMlDZ1yqw44nTulEamZvhpiLIj8hPsxpve8= r2d2k-cloud" \
 --metadata-from-file user-data=deploy_auto.sh \
 --zone ru-central1-b
```
