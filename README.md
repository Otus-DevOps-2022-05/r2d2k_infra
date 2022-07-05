# Домашние задания по инфраструктуре

Оглавление:
<!-- MarkdownTOC autolink=true autoanchor=false-->

- [01 - Bastion host homework \(SSH\)](#01---bastion-host-homework-ssh)
- [02 - Bastion host homework \(OpenVPN\)](#02---bastion-host-homework-openvpn)
- [03 - YC practice](#03---yc-practice)
- [04 - Packer](#04---packer)
- [05 - Terraform](#05---terraform)

<!-- /MarkdownTOC -->


## 01 - Bastion host homework (SSH)
**Задание №01-1:** Исследовать способ подключения к `someinternalhost` в одну команду из вашего рабочего устройства, проверить работоспособность найденного решения

**Решение №01-1:** Использовать ключ `ssh -J`, который позволяет прокладывать подключение через один или несколько промежуточных хостов.

**Результат №01-1:**
```console
localuser@localhost:~$ ssh -i ~/.ssh/appuser -J appuser@bastion_ext_ip appuser@someinternalhost_int_ip

Welcome to Ubuntu 15.10 (GNU/Linux 4.2.0-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Wen Oct 21 07:28:00 2015 from 0.0.0.0
appuser@someinternalhost:~$
```


**Задание №01-2:** Предложить вариант решения для подключения из консоли при помощи команды вида `ssh someinternalhost` из локальной консоли рабочего устройства, чтобы подключение выполнялось по алиасу `someinternalhost`.

**Решение №01-2:** Настроить alias в локальном конфиге ssh
```console
localuser@localhost:~$ cat ~/.ssh/config

Host someinternalhost
    HostName someinternalhost_int_ip
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyJump appuser@bastion_ext_ip
```

**Результат №01-2:**
```console
localuser@localhost:~$ ssh someinternalhost

Welcome to Ubuntu 15.10 (GNU/Linux 4.2.0-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Wen Oct 21 07:28:00 2015 from 0.0.0.0
appuser@someinternalhost:~$
```


## 02 - Bastion host homework (OpenVPN)

Данные для проверки VPN сервера:
```
bastion_IP = 51.250.95.231
someinternalhost_IP = 10.128.0.19
```


## 03 - YC practice
**Задание №03-1:** При помощи `yc` cоздать VM, установить приложение

**Решение №03-1:** Все работы выполняем в несколько шагов
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

**Результат №03-1:**
Машина создана, приложение развёрнуто, ждёт проверки, данные ниже.

_Моя ошибка - пытаться использовать новые версии ПО, но автотесты этого не оценили._
```
testapp_IP = 62.84.121.73
testapp_port = 9292
```


**Задание №03-2:** При помощи `yc` cоздать VM, установить приложение. Использовать метаданные для автоматизации работы

**Решение №03-2:** Собираем все скрипты в один, указываем его в метаданных `yc`

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


## 04 - Packer

**Задание №04-1:** Параметризируйте созданный вами шаблон.

**Решение №04-1:**
Создаём файл с параметрами (variables.json)
```json
{
    "mv_service_account_key_file": "key.json",
    "mv_folder_id": "WYDIWYG",
    "mv_source_image_family": "geeeen-toooo"
}
```

Сам файл для `packer` в итоге выглядит так (ubuntu16.json)
```json
{
    "variables": {
        "mv_service_account_key_file": "",
        "mv_folder_id": "",
        "mv_source_image_family": ""
    },
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `mv_service_account_key_file`}}",
            "folder_id": "{{user `mv_folder_id`}}",
            "source_image_family": "{{user `mv_source_image_family`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Проверяем: `packer validate -var-file=variables.json ubuntu16.json`, если всё ОК, то запускаем: `packer build -var-file=variables.json ubuntu16.json`

**Результат №04-1:**
Смотрим, что у нас есть из образов в облаке: `yc compute image list`
```console
$ yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| fd8p7m7pgsaqs22nvqsd | reddit-base-1656178022 | reddit-base | f2ej52ijfor6n4fg5v0f | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```
Образ создан, задание выполнено.


**Задание №04-2:** Построение bake-образа (по желанию). Попробуйте "запечь" (bake) в образ ВМ все зависимости приложения и сам код приложения.
Результат должен быть таким: запускаем инстанс из созданного образа и на нем сразу же имеем запущенное приложение.

**Решение №04-2:**
Шаблон для `packer` выглядит так (immutable.json)
```json
{
    "variables": {
        "mv_service_account_key_file": "",
        "mv_folder_id": "",
        "mv_source_image_family": "",
        "mv_image_family": ""
    },
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `mv_service_account_key_file`}}",
            "folder_id": "{{user `mv_folder_id`}}",
            "source_image_family": "{{user `mv_source_image_family`}}",
            "image_name": "{{user `mv_image_family`}}-{{timestamp}}",
            "image_family": "{{user `mv_image_family`}}",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/wait_120.sh",
            "execute_command": "{{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "file",
            "source": "files/reddit-app.service",
            "destination": "/tmp/reddit-app.service"
        },
        {
            "type": "shell",
            "script": "files/install_app.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/cleanup.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Для автоматического запуска приложения создаём Unit файл systemd (reddit-app.service).
Файл, конечно, не фонтан, но мы же учимся :)
```ini
[Unit]
Description="Simplr Reddit App"
After=network.target

[Service]
Type=simple
WorkingDirectory=/app/reddit
ExecStart=/usr/local/bin/puma

[Install]
WantedBy=multi-user.target
```

**Результат №04-2:**
Заходим в облако, создаём машину, в качестве диска выбираем "Пользовательские", далее выбираем образ, созданный на предыдущем шаге.
После создания машины мы можем обратиться к внешнему адресу, порт 9292. В ответ получим наше приложение.


**Задание №04-3:** Автоматизация создания ВМ

**Решение №04-3:**
На предыдущем шаге мы получили ID образа, используем его для скрипта `yc`, сохраняем в (create-reddit-vm.sh)
```bash
#!/bin/sh

yc compute instance create \
 --name reddit-app-bake \
 --hostname reddit-app-bake \
 --memory=4 \
 --create-boot-disk image-id=fd8p7m7pgsaqs22nvqsd,size=10GB \
 --network-interface subnet-name=net-1-ru-central1-b,nat-ip-version=ipv4 \
 --metadata serial-port-enable=1 \
 --ssh-key ~/.ssh/key-cloud.pub \
 --zone ru-central1-b
```

**Результат №04-3:**
Скрипт создаёт ВМ из подготовленного образа, имеем машину с запущеным приложением.


## 05 - Terraform

Так, как задания писались давно, то при использовании свежих версий Terraform у нас будут проблемы с автотестированием. Рекомендуют использовать версию [Terraform 0.12.8](https://hashicorp-releases.website.yandexcloud.net/terraform/0.12.8).


**Задание №05-1:**


**Решение №05-1:**

Добавляем в `main.tf` описание провайдера `yandex`:
```hcl
provider "yandex" {
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<id_облака>"
  folder_id = "<id_каталога>"
  zone      = "ru-central1-a"
}
...
```

Параметры для провайдера можно посмотреть при помощи `yc`:
```console
$ yc config list
token: AgAAAAA_*****************************9s
cloud-id: ******************cj
folder-id: ******************nu
```

В папке, где мы разместили `main.tf`, выполняем инициализацию провайдера:
```console
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "yandex" (terraform-providers/yandex) 0.56.0...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.yandex: version = "~> 0.56"

Warning: registry.terraform.io: This version of Terraform has an outdated GPG key and is unable to verify new provider releases. Please upgrade Terraform to at least 0.12.31 to receive new provider updates. For details see: https://discuss.hashicorp.com/t/hcsec-2021-12-codecov-security-event-and-hashicorp-gpg-key-exposure/23512

Warning: registry.terraform.io: For users on Terraform 0.13 or greater, this provider has moved to yandex-cloud/yandex. Please update your source in required_providers.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

```

Если возникнут проблемы со скачиванием провайдера, то это можно сделать вручную. Скачать какой-нибудь древний релиз с [github.com](https://github.com/yandex-cloud/terraform-provider-yandex/releases), распаковать архив в папку и указать на него вручную, при инициализации `terraform init -plugin-dir путь_к_папке_с_провайдером`. С версией 0.44 все задания отрабатывали без ошибок.

Оформляем `main.tf`

```hcl
provider "yandex" {
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<id_облака>"
  folder_id = "<id_каталога>"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = <id_образа>
    }
  }

  network_interface {
    subnet_id = <id_подсети>
    nat       = true
  }
}
```

Идентификаторы образа и подсети можно узнать через `yc`:
```console
$ yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| ******************or | reddit-base-********54 | reddit-base | ******************0f | READY  |
| ******************9v | reddit-full-********80 | reddit-full | ******************0f | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

```console
$ yc vpc subnet list
+----------------------+---------------------+----------------------+----------------+---------------+-----------------+
|          ID          |        NAME         |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+---------------------+----------------------+----------------+---------------+-----------------+
| ******************62 | net-1-ru-central1-c | ******************qg |                | ru-central1-c | [10.130.0.0/24] |
| ******************rd | net-1-ru-central1-b | ******************qg |                | ru-central1-b | [10.129.0.0/24] |
| ******************s1 | net-1-ru-central1-a | ******************qg |                | ru-central1-a | [10.128.0.0/24] |
+----------------------+---------------------+----------------------+----------------+---------------+-----------------+
```

После `terraform apply` получаем созданную по нашей конфигурации виртуальную машину:
```console
...
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
...
```

Проверяем ip адрес:
```console
$ terraform show | grep nat_ip_address
        nat_ip_address     = "51.250.73.122"
```

Пробуем подключиться:
```console
$ ssh ubuntu@51.250.73.122
The authenticity of host '51.250.73.122 (51.250.73.122)' can't be established.
ED25519 key fingerprint is SHA256:BhSUxvuIWQPYucjFDtnSPiBMGWlOvZ44IJWD5PSr5I0.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '51.250.73.122' (ED25519) to the list of known hosts.
ubuntu@51.250.73.122's password:
Permission denied, please try again.
ubuntu@51.250.73.122's password:
Permission denied, please try again.
ubuntu@51.250.73.122's password:
ubuntu@51.250.73.122: Permission denied (publickey,password).
```

Ничего не получится, так как на удалённой машине отсутствует наш публичный ssh-ключ, да и пароль мы не знаем.

Генерируем пару ключей (можем взять их из предыдущего задания), добавляем через секцию метаданных в ресурс нашей виртуальной машины:
```hcl
...
metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/ubuntu.pub")}"
}
...
```

Удаляем машину через `terraform destroy`, создаём новую: `terraform apply`.
Получаем ip адрес:
```console
$ terraform show | grep nat_ip_address
        nat_ip_address     = "51.250.78.21"
```

 Успешно подключаемся к новой машине по ssh с использованием ключа:
```console
$ ssh -i ~/.ssh/ubuntu ubuntu@51.250.78.21
The authenticity of host '51.250.78.21 (51.250.78.21)' can't be established.
ED25519 key fingerprint is SHA256:WESlP64yddMCJCBcYotyjcJBxXn7HXqqKLGkoLWJtMw.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '51.250.78.21' (ED25519) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-210-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
ubuntu@******************07:~$ logout
Connection to 51.250.78.21 closed.

```

Для удобства выводим в консоль адрес нашей виртуальной машины.
Для этого создаём в нашей рабочей папке файл `outputs.tf`:
```hcl
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

Обновляем статус и получаем ip машины:
```console
$ terraform refresh
yandex_compute_instance.app: Refreshing state... [id=******************07]

Outputs:

external_ip_address_app = 51.250.78.21

```

Для автоматического запуска приложения после старта машины будем использовать systemd unit-файл (puma.service):
```ini
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

Доставляем этот unit-файл на удалённую машину при помощи `provisioner "file"`:
```hcl
...
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
...
```

Настройку приложения выполним при помощи скрипта (deploy.sh):
```sh
#!/bin/bash
set -e
APP_DIR=${1:-$HOME}
sleep 120
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit
cd $APP_DIR/reddit
bundle install
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
```

Для запуска скрипта на удалённой машине используем `provisioner "remote-exec"`:
```hcl
...
provisioner "remote-exec" {
  script = "files/deploy.sh"
}
...
```

Для подключения к созданной машине и запуска скриптов используем `connection`:
```hcl
...
connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file("~/.ssh/ubuntu")
}
...
```

Можно использовать переменные, чтобы вынести изменяемые параметры за пределы основных файлов. Опишем используемые переменные в отдельном файле (variables.tf):
```hcl
variable "service_account_key_file" {
  description = "Path to service account key file"
}

variable "cloud_id" {
  description = "Cloud"
}

variable "folder_id" {
  description = "Folder"
}

variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "image_id" {
  description = "Image id for VM"
}

variable "subnet_id" {
  description = "ID for subnet"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}
```

Значения переменных задаём в другом файле (terraform.tfvars):
```ini
service_account_key_file    = "key.json"
cloud_id                    = "00000000000000000000"
folder_id                   = "00000000000000000000"
zone                        = "00-00000000-0"
image_id                    = "00000000000000000000"
subnet_id                   = "00000000000000000000"
public_key_path             = "~/.ssh/ubuntu.pub"
private_key_path            = "~/.ssh/ubuntu"
```

Итоговый основной файл конфигурации (main.tf) будет выглядеть так:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  connection {
    type        = "ssh"
    host        = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "./files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Уничтожаем `terraform destroy` старую машину, если она существует и применяем новую конфигурацию `terraform apply`.

**Результат №05-2:**
После применения конфигурации в облаке создаётся виртуальная машина. Так как машина создана из образа, подготовленного ранее, то на ней уже установлены все компоненты, которые необходимы для запуска нашего приложения. После создания машины начинают отрабатывать `provisioner`, один переносит на удалённую машину unit-файл для запуска приложения, второй выполняет развёртывание приложения из репозитория github. Также в процессе создания машины на неё копируется публичный ssh ключ пользователя, что позволит нам подключаться к удалённой консоли. После завершения работы `terraform apply` мы получим адрес созданной машины с установленным и запущенным приложением. Проверяем через браузер - всё работает.


**Задание №05-2:**
Создайте файл `lb.tf` и опишите в нем в коде terraform создание HTTP балансировщика, направляющего трафик на наше развернутое приложение на инстансе reddit-app. Проверьте доступность приложения по адресу балансировщика. Добавьте в output переменные адрес балансировщика.

**Решение №05-2:**
Создаём файл `lb.tf`, описываем в нём два ресурса: `yandex_lb_target_group` и `yandex_lb_network_load_balancer`. В ресурсе `yandex_lb_target_group` описываем `target`, который указывает на внутренний IP-адрес нашей виртуальной машины с приложением reddit-app. В секции `listener` ресурса `yandex_lb_network_load_balancer` указываем внешний порт, на который будут обращаться клиенты балансировщика, внутренний порт, на который будут пренаправляться их запросы, ну и протокол обмена. Подключаем к балансировщику группу, созданную ранее, в итоге получаем следующую конфигурацию:
```hcl
resource "yandex_lb_network_load_balancer" "lb" {
  name = "reddit-app-loadbalancer"

  listener {
    name        = "reddit-app-listener"
    port        = 80
    target_port = 9292
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lb_tg.id
    healthcheck {
      name = "http"
      http_options {
        port = 9292
      }
    }
  }
}

resource "yandex_lb_target_group" "lb_tg" {
  name = "reddit-app-targetgroup"

  target {
    address   = yandex_compute_instance.app.network_interface.0.ip_address
    subnet_id = var.subnet_id
  }
}
```

Для вывода данных об адресе балансировщика добавим одну строку в `outputs.tf`:
```hcl
output "external_ip_address_lb" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```

**Результат №05-2:**
После применения указанной выше конфигурации мы получим балансировщик, прослушивающий порт http и перенаправляющий запросы на порт 9292 нашей виртуальной машины.


**Задание №05-3:**
Добавьте в код еще один terraform ресурс для нового инстанса приложения, например reddit-app2, добавьте его в балансировщик и проверьте, что при остановке на одном из инстансов приложения (например systemctl stop puma), приложение продолжает быть доступным по адресу балансировщика;

Добавьте в output переменные адрес второго инстанса;

Какие проблемы вы видите в такой конфигурации приложения?

**Решение №05-3:**
Решаем задачу простым копированием ресурса и переименованием его идентификатора. Основной файл конфигурации (main.tf) примет следующий вид:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_compute_instance" "app1" {
  name = "reddit-app1"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  connection {
    type        = "ssh"
    host        = yandex_compute_instance.app1.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "./files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  connection {
    type        = "ssh"
    host        = yandex_compute_instance.app2.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "./files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Дополнительный сервер нужно учесть в конфигурации балансировщика (lb.tf), добавляем ещё один `target` к ресурсу группы:
```hcl
resource "yandex_lb_network_load_balancer" "lb" {
  name = "reddit-app-loadbalancer"

  listener {
    name        = "reddit-app-listener"
    port        = 80
    target_port = 9292
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lb_tg.id
    healthcheck {
      name = "http"
      http_options {
        port = 9292
      }
    }
  }
}

resource "yandex_lb_target_group" "lb_tg" {
  name = "reddit-app-targetgroup"

  target {
    address   = yandex_compute_instance.app1.network_interface.0.ip_address
    subnet_id = var.subnet_id
  }

  target {
    address   = yandex_compute_instance.app2.network_interface.0.ip_address
    subnet_id = var.subnet_id
  }
}
```

Не забываем про изменения в файле вывода переменных:
```hcl
output "external_ip_address_app1" {
  value = yandex_compute_instance.app1.network_interface.0.nat_ip_address
}

output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
}
```


**Результат №05-3:**
После применения конфигурации получаем балансировщик, за ним два сервера с приложением. За счёт проверки на активность порта 9292 на каждом из серверов приложений балансировщик понимает, какой из серверов может прнимать подключения. При отсутствии ответа от одного из серверов трафик на него не преренаправляется.

Проблема: каждый сервер работает со своей базой данных, поэтому работать всё будет очень странно. Периодические запросы аутентификации, независимое ведение записей блога на каждом из серверов. При новом подключении к балансировщику можно оказаться на сервере, где нет записей, которые ты сохранил в прошлый раз.


**Задание №05-4:**
Как мы видим, подход с созданием доп. инстанса копированием кода выглядит нерационально, т.к. копируется много кода. Удалите описание reddit-app2 и попробуйте подход с заданием количества инстансов через параметр ресурса count. Переменная count должна задаваться в параметрах и по умолчанию равна 1.

**Решение №05-4:**
В описание переменных (variables.tf) добавляем счётчик серверов, значение по умолчанию равно единице:
```hcl
...
variable "app_servers_count" {
  description = "Application servers count"
  default     = 1
}
...
```

Значения переменных указываем в файле (terraform.tfvars):
```ini
service_account_key_file    = "key.json"
cloud_id                    = "00000000000000000000"
folder_id                   = "00000000000000000000"
zone                        = "00-00000000-0"
image_id                    = "00000000000000000000"
subnet_id                   = "00000000000000000000"
public_key_path             = "~/.ssh/id_rsa.pub"
private_key_path            = "~/.ssh/id_rsa"
app_servers_count           = 2
```

Удаляем копию ресурса, добавляем счётчик серверов, в имени сервера используем счётчик, чтобы имена создаваемых серверов не были одинаковыми. Основной файл уонфигурации примет такой вид:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_compute_instance" "app" {
  name  = "reddit-app-${count.index}"
  zone  = var.zone
  count = var.app_servers_count

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  connection {
    type        = "ssh"
    host        = self.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "./files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

В настройке балансировщика (lb.tf) для группы применим динамический ресурс:
```hcl
...
resource "yandex_lb_target_group" "lb_tg" {
  name = "reddit-app-targetgroup"

  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      address   = target.value
      subnet_id = var.subnet_id
    }
  }
}
...
```

В файле вывода переменных (outputs.tf) также учитываем изменения:
```hcl
...
output "external_ip_address_app" {
  value = [for ip in yandex_compute_instance.app.*.network_interface.0.nat_ip_address : ip]
}
...
```

**Результат №05-4:**
После применения конфигурации получаем балансировщик и несколько серверов с приложением за ним. Количество серверов определяется переменной `app_servers_count` и по умолчанию равно единице.
