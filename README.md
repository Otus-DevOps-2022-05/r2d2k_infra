# Домашние задания по инфраструктуре

Оглавление:
<!-- MarkdownTOC autolink=true -->

- [01 - Bastion host homework \(SSH\)](#01---bastion-host-homework-ssh)
- [02 - Bastion host homework \(OpenVPN\)](#02---bastion-host-homework-openvpn)
- [03 - YC practice](#03---yc-practice)
- [04 - Packer](#04---packer)
- [05 - Terraform-1](#05---terraform-1)
- [06 - Terraform-2](#06---terraform-2)
- [07 - Ansible-1](#07---ansible-1)
- [08 - Ansible-2](#08---ansible-2)
- [09 - Ansible-3](#09---ansible-3)
- [10 - Ansible-4](#10---ansible-4)

<!-- /MarkdownTOC -->

---

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

---

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

---

## 02 - Bastion host homework (OpenVPN)

Данные для проверки VPN сервера:
```
bastion_IP = 51.250.95.231
someinternalhost_IP = 10.128.0.19
```

---

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

---

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

---

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
| ******************sd | reddit-base-********22 | reddit-base | ******************0f | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```
Образ создан, задание выполнено.

---

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

---

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

---

## 05 - Terraform-1

Так, как задания писались давно, то при использовании свежих версий Terraform у нас будут проблемы с автотестированием. Рекомендуют использовать версию [Terraform 0.12.8](https://hashicorp-releases.website.yandexcloud.net/terraform/0.12.8).


**Задание №05-1:** Знакомство с Terraform, часть 1


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

**Результат №05-1**
После применения конфигурации в облаке создаётся виртуальная машина. Так как машина создана из образа, подготовленного ранее, то на ней уже установлены все компоненты, которые необходимы для запуска нашего приложения. После создания машины начинают отрабатывать `provisioner`, один переносит на удалённую машину unit-файл для запуска приложения, второй выполняет развёртывание приложения из репозитория github. Также в процессе создания машины на неё копируется публичный ssh ключ пользователя, что позволит нам подключаться к удалённой консоли. После завершения работы `terraform apply` мы получим адрес созданной машины с установленным и запущенным приложением. Проверяем через браузер - всё работает.

---

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

---

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

---

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

---

## 06 - Terraform-2

**Задание №06-1:** Знакомство с Terraform, часть 2

**Решение №06-1:**

Из предыдущего занятия удаляем балансировщик и переменные, связанные с ним. Количество создаваемых серверов устанавливаем в единицу.
В основной файл конфигурации добавим создание сети и подсети для наших серверов.
```hcl
...
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddis-app-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
...
```

В ресурсе виртуальной машины делаем ссылку на созданную подсеть.
```hcl
...
network_interface {
  subnet_id = yandex_vpc_subnet.app-subnet.id
  nat       = true
}
...
```

Применяем конфигурацию, всё работает, удаляем машины.


По условию задачи нам нужно разнести базу данных и приложение на разные машины. Для начала создадим образы для этих машин. Модифицируем `ubuntu16.json` из прошлого задания, получаем две конфигурации `packer` для серверов базы данных и приложения.

Содержимое `app.json`:
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
            "image_name": "reddit-app-{{timestamp}}",
            "image_family": "reddit-app",
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
            "script": "scripts/cleanup.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Содержимое `db.json`:
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
            "image_name": "reddit-db-{{timestamp}}",
            "image_family": "reddit-db",
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
            "script": "scripts/install_mongodb.sh",
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

Собираем образы: `packer build -var-file=variables.json app.json` и `packer build -var-file=variables.json db.json`.
Проверяем, что образы созданы `yc compute image list`:
```console
$ yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| ******************or | reddit-base-********54 | reddit-base | ******************0f | READY  |
| ******************bi | reddit-app-********01  | reddit-app  | ******************hp | READY  |
| ******************9q | reddit-db-********94   | reddit-db   | ******************hp | READY  |
| ******************9v | reddit-full-********80 | reddit-full | ******************0f | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

Делим основной файл конфигурации на несколько.

Содержимое файла `app.tf`:
```hcl
resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  zone = var.zone

  labels = {
    tags = "reddit-app"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Содержимое файла `db.tf`:
```hcl
resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  zone = var.zone

  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Содержимое файла `vpc.tf`:
```hcl
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddis-app-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```

Содержимое файла `main.tf`:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
```

Содержимое файла `variables.tf`:
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

variable "app_disk_image_id" {
  description = "Disk image id for VM (app)"
}

variable "db_disk_image_id" {
  description = "Disk image id for VM (db)"
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

variable "app_servers_count" {
  description = "Application servers count"
  default     = 1
}
```

Содержимое файла `outputs.tf`:
```hcl
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}

output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```

Применяем конфигурацию `terraform apply`, смотрим `yc compute instance list`, что получилось:
```console
$ yc compute instance list
+----------------------+------------+---------------+---------+---------------+---------------+
|          ID          |    NAME    |    ZONE ID    | STATUS  |  EXTERNAL IP  |  INTERNAL IP  |
+----------------------+------------+---------------+---------+---------------+---------------+
| ******************c5 | reddit-db  | ru-central1-a | RUNNING | 51.250.70.254 | 192.168.10.14 |
| ******************35 | reddit-app | ru-central1-a | RUNNING | 51.250.90.200 | 192.168.10.32 |
+----------------------+------------+---------------+---------+---------------+---------------+
```

Заходим на `reddit-app`, проверяем версию `ruby`:
```console
$ ssh -i ~/.ssh/ubuntu ubuntu@51.250.90.200 ruby --version
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
```

Заходим на `reddit-db`, проверяем версию `mongodb`:
```console
$ ssh -i ~/.ssh/ubuntu ubuntu@51.250.70.254 mongod --version
db version v2.6.10
2022-07-06T05:40:13.188+0000 git version: nogitversion
2022-07-06T05:40:13.188+0000 OpenSSL version: OpenSSL 1.0.2g  1 Mar 2016
```

Всё в порядке, образы рабочие, можно удалить машины: `terraform destroy`.


Теперь можем оформить сервер БД и сервер приложений отдельными модулями. Для этого создаём папку `modules`, в ней две папки `app` и `db`. В каждую папку переносим файлы конфигурации с переименованием их в `main.tf` : файл `app.tf`, описывающий сервер приложений, в папку `app`, а файл `db.tf`, описывающий сервер БД, в папку `db`. Дополняем папки файлами `variables.tf`, в которых указываем переменные, использующиеся в описании серверов. Также каждый модуль дополняем файлом `outputs.tf`. В итоге получаем такую структуру папок:
```console
.
│   main.tf
│   outputs.tf
│   terraform.tfvars
│   variables.tf
│
└───modules
    ├───app
    │       main.tf
    │       outputs.tf
    │       variables.tf
    │
    └───db
            main.tf
            outputs.tf
            variables.tf
```
Файл описания сетей `vpc.tf` удаляем, вместо автоматизированного создания подсети используем существующую, указав её идентификатор в файле `terraform.tfvars`.
Посмотрим, что у нас есть из подсетей:
```console
$ yc vpc subnet list
+----------------------+---------------------+----------------------+----------------+---------------+-----------------+
|          ID          |        NAME         |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+---------------------+----------------------+----------------+---------------+-----------------+
| ******************g9 | net-1-ru-central1-c | ******************5v |                | ru-central1-c | [10.130.0.0/24] |
| ******************ng | net-1-ru-central1-b | ******************5v |                | ru-central1-b | [10.129.0.0/24] |
| ******************ib | net-1-ru-central1-a | ******************5v |                | ru-central1-a | [10.128.0.0/24] |
+----------------------+---------------------+----------------------+----------------+---------------+-----------------+
```

Если подсеть отсутствует - создаём руками через консоль облака.

Содержимое `app\main.tf`:
```hcl
resource "yandex_compute_instance" "app" {
  name = "reddit-app-${var.environment}"
  zone = var.zone

  labels = {
    tags = "reddit-app-${var.environment}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Содержимое `app\variables.tf`:
```hcl
variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "app_disk_image_id" {
  description = "Disk image id for VM (app)"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "subnet_id" {
  description = "ID for subnet"
}

variable "environment" {
  description = "Current environment (stage, prod, etc)"
}
```

Содержимое `app\outputs.tf`:
```hcl
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

Содержимое файлов модуля `db` аналогично, с учётом изменения идентификаторов и переменных. В корневой папке меняем `main.tf`, добавляя созданные модули. Меняем `outputs.tf`, добавляя выходные переменные модулей.

Содержимое `main.tf`:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

module "app" {
  source            = "./modules/app"
  public_key_path   = var.public_key_path
  app_disk_image_id = var.app_disk_image_id
  subnet_id         = var.subnet_id
  zone              = var.zone
  environment       = var.environment
}

module "db" {
  source           = "./modules/db"
  public_key_path  = var.public_key_path
  db_disk_image_id = var.db_disk_image_id
  subnet_id        = var.subnet_id
  zone             = var.zone
  environment       = var.environment
}
```

Содержимое `outputs.tf`:
```hcl
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}

output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
```

Проверяем конфигурацию на корректность:
```console
$ terraform validate

Error: Module not installed

  on main.tf line 8:
   8: module "app" {

This module is not yet installed. Run "terraform init" to install all modules
required by this configuration.


Error: Module not installed

  on main.tf line 16:
  16: module "db" {

This module is not yet installed. Run "terraform init" to install all modules
required by this configuration.
```

Для использования модулей их нужно установить:
```console
$ terraform get
- app in modules\app
- db in modules\db
```

После установки модулей проверка завершается без проблем.
```console
$ terraform validate
Success! The configuration is valid.
```

Далее применяем конфигурацию, проверяем, что машины доступны по ssh и удаляем их.


Модули позволяют переиспользовать код. Создадим два окружения, для этого в корневой папке создаём два каталога: `stage` и `prod`. В каждый копируем комплект из `main.tf`, `outputs.tf`, `key.json`, `terraform.tfvars`, `variables.tf`. В файлах `main.tf` обновляем путь до модулей: "./modules/db" => "../modules/db" и "./modules/app" => "../modules/app".

Проверяем корректность каждого окружения:
- идём в stage
- инициализируем его:     `terraform init`
- проверяем корректность: `terraform validate`
- создаём машины:         `terraform apply`
- удаляем их:             `terraform destroy`

**Результат №06-1:**
Мы научились работать с модулями и переиспользовать код.

---

**Задание №06-2:**
1. Настройте хранение стейт файла в удаленном бекенде (remote backends) для окружений stage и prod, используя Yandex Object Storage в качестве бекенда. Описание бекенда нужно вынести в отдельный файл backend.tf
2. Перенесите конфигурационные файлы Terraform в другую директорию (вне репозитория). Проверьте, что state-файл (terraform.tfstate) отсутствует. Запустите Terraform в обеих директориях и проконтролируйте, что он "видит" текущее состояние независимо от директории, в которой запускается
3. Попробуйте запустить применение конфигурации одновременно, чтобы проверить работу блокировок

**Решение №06-2:**
Прекрасное [описание](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-state-storage) хранения состояния в Object Stirage есть на сайте Yandex. Создаём бакет для хранения состояния `terraform`, подробная инструкция доступна по [ссылке](https://cloud.yandex.ru/docs/storage/operations/buckets/create). Имя бакета должно быть уникальным в пределах всего облака, для примера возьмём `terrastate-202205`. Для доступа к бакету нам потребуется статический ключ, привязанный к сервисному аккаунту.

Проверяем, какие сервисные аккаунты у нас созданы:
```console
$ yc iam service-account list
+----------------------+--------------+
|          ID          |     NAME     |
+----------------------+--------------+
| ******************5r | yc-packer    |
| ******************88 | yc-terraform |
+----------------------+--------------+
```

Создаём статический ключ:
```console
$ yc iam access-key create --service-account-name yc-terraform --description "Key is for Object Storage"
access_key:
  id: ******************9d
  service_account_id: ******************88
  created_at: "0000-00-00T00:00:00.000000000Z"
  description: Key is for Object Storage
  key_id: ******-****************BU
secret: ************************-*************Yb
```

Ключ сохраняем, т.к. его значение можно узнать только во время создания. KEY ID мы видим, а вот secret уже нет.
```console
$ yc iam access-key list --service-account-name yc-terraform
+----------------------+----------------------+---------------------------+
|          ID          |  SERVICE ACCOUNT ID  |          KEY ID           |
+----------------------+----------------------+---------------------------+
| ******************9d | ******************88 | ******-****************BU |
+----------------------+----------------------+---------------------------+
```

 В каждой из папок `stage` и `prod` создаём описание бэкенда(backend.tf):
```hcl
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terrastate-202205"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = "******-****************BU"
    secret_key = "************************-*************Yb"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

Удаляем файлы состояния `$ rm terraform.tfstate terraform.tfstate.backup`. При попытке просмотра состояния конфигурации получаем ошибку:
```console
$ terraform show
Backend reinitialization required. Please run "terraform init".
Reason: Initial configuration of the requested backend "s3"

The "backend" is the interface that Terraform uses to store state,
perform operations, etc. If this message is showing up, it means that the
Terraform configuration you're using is using a custom configuration for
the Terraform backend.

Changes to backend configurations require reinitialization. This allows
Terraform to setup the new configuration, copy existing state, etc. This is
only done during "terraform init". Please run that command now then try again.

If the change reason above is incorrect, please verify your configuration
hasn't changed and try again. At this point, no changes to your existing
configuration or state have been made.


Error: Initialization required. Please see the error message above.
```

Инициализируем:
```console
$ terraform init
Initializing modules...

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.yandex: version = "~> 0.56"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Настройки бэкенда можно выносить в отдельные файлы, [подробности](https://www.terraform.io/language/settings/backends/configuration) можно прочитать в официальной документации. В некоторых случая это будет полезным, т.к. можно распространять конфигурацию без реальных реквизитов доступа.

К примеру, файл настроек бэкенда(backend.tf) из такого:
```hcl
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terrastate-202205"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = "******-****************BU"
    secret_key = "************************-*************Yb"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

Превращается в такой:
```hcl
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terrastate-202205"
    region     = "ru-central1"
    key        = "terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

Учётные данные выносим в отдельный файл(config.s3.tfbackend):
```ini
access_key = "******-****************BU"
secret_key = "************************-*************Yb"
```

При этом первоначальную инициализацию окружения производим командой `terraform init -backend-config=config.s3.tfbackend`. Настройки бэкенда будут сохранены в локальной папке `.terraform`.


**Результат №06-2:**
Для проверки работы бэкенда применяем настройки одного из окружений `terraform apply`. После создания машин видим, что файл состояния в текущей папке не появился. Если мы перенесём папку с проектом в другое место на диске, то состояние не изменится, т.к. статус хранится в Object Storage. При одновременном выполнении заданий из разных папок, но с одним бэкендом не происходило никаких блокировок, но появлялась ошибка создания ресурса с одинаковым именем.

---

**Задание №06-3:**
1. Добавьте необходимые provisioner в модули для деплоя и работы приложения. Файлы, используемые в provisioner, должны находится в директории модуля
2. Опционально можете реализовать отключение provisioner в зависимости от значения переменной
3. Добавьте описание в README.md

P.S. Приложение получает адрес БД из переменной окружения DATABASE_URL

**Решение №06-3:**
Настроим одно из окружений, например `stage`. В папке модуля создаём каталог `files`, переносим в него ранее созданные unit-файл `puma.service` и скрипт настройки `deploy.sh`. В основной файл конфигурации модуля `main.tf` возвращаем блоки `connection` и `provisioner`. Для указания ссылок на расположение файлов модуля используем переменную `${path.module}`.
```hcl
...
  connection {
    type        = "ssh"
    host        = self.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
...
```

В файл описания переменных модуля `variables.tf` добавим новую, указывающую на приватный ключ:
```hcl
...
variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}
...
```

Не забываем добавить переменную `private_key_path` в основной файл `main.tf` окружения `stage`:
```hcl
...
module "app" {
  source            = "../modules/app"
  public_key_path   = var.public_key_path
  private_key_path   = var.private_key_path
  app_disk_image_id = var.app_disk_image_id
  subnet_id         = var.subnet_id
  zone              = var.zone
  environment       = var.environment
}
...
```

Применяем конфигурацию `terraform apply`, видим, что созданы две машины. На сервере приложений отработал скрипт деплоя, сервис `puma` запущен, порт 9292 прослушивается. При обращении браузером к нашему приложению получим ошибку _"Can't show blog posts, some problems with database. Refresh?"_. Причиной ошибки является отсутствие доступа к базе данных. Правильно, ранее БД и приложение располагались на одном сервере, а теперь они разнесены. Смотрим на код приложения, в самом начале файла app.rb видим создание подключения к БД:
```ruby
...
configure do
    db = Mongo::Client.new([ ENV['DATABASE_URL'] || '127.0.0.1:27017' ], database: 'user_posts', heartbeat_frequency: 2)
    set :mongo_db, db[:posts]
    set :comments_db, db[:comments]
    set :users_db, db[:users]
    set :bind, '0.0.0.0'
    enable :sessions
end
...
```
Если задана переменная окружения `DATABASE_URL`, то адрес сервера берём из неё, если не указана, то используем локальный сервер БД. Чтобы задать переменную окружения для сервиса, нужно изменить его unit-файл. Смотрим [документацию](https://systemd.io/TRANSIENT-SETTINGS/), видим, что переменные окружения можно задать через "Environment=DATABASE_URL=server_ip". Адрес сервера мы возьмём из output переменной модуля db. Чтобы вписать переменную в файл во время выполнения развёртывания, мы используем функцию [`templatefile`](https://www.terraform.io/language/functions/templatefile). Скопируем файл `puma.service` в `puma.service.tftpl` и добавим в него строку `Environment=DATABASE_URL=${MONGODB_DATABASE_URL}`. Для передачи в модуль приложения адреса сервера БД добавим новую переменную `database_ip`. В итоге наша конфигурация примет вид:

Содержимое `puma.service.tftpl` модуля `app`:
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
Environment=DATABASE_URL=${MONGODB_DATABASE_URL}

[Install]
WantedBy=multi-user.target
```

Файл `variables.tf` модуля `app`:
```hcl
variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "app_disk_image_id" {
  description = "Disk image id for VM (app)"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}

variable "subnet_id" {
  description = "ID for subnet"
}

variable "environment" {
  description = "Current environment (stage, prod, etc)"
}

variable "database_ip" {
  description = "IP address of Mongodb server"
}
```

Основной файл `main.tf` модуля `app`:
```hcl
resource "yandex_compute_instance" "app" {
  name = "reddit-app-${var.environment}"
  zone = var.zone

  labels = {
    tags = "reddit-app-${var.environment}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image_id
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
    content     = templatefile("${path.module}/files/puma.service.tftpl", { MONGODB_DATABASE_URL = var.database_ip })
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Основной файл `main.tf` окружения `stage`:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

module "app" {
  source            = "../modules/app"
  public_key_path   = var.public_key_path
  private_key_path  = var.private_key_path
  app_disk_image_id = var.app_disk_image_id
  subnet_id         = var.subnet_id
  zone              = var.zone
  environment       = var.environment
  database_ip       = module.db.external_ip_address_db
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  db_disk_image_id = var.db_disk_image_id
  subnet_id        = var.subnet_id
  zone             = var.zone
  environment      = var.environment

}
```

Применяем конфигурацию, заходим на сервер приложений по SSH, смотрим, как отработал наш шаблон:
```console
$ cat /etc/systemd/system/puma.service
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
Environment=DATABASE_URL=51.250.12.230

[Install]
WantedBy=multi-user.target
```

Переменная окружения `DATABASE_URL` появилась, адрес сервера баз данных ей присвоен. Пробуем подключиться к приложению браузером - снова получаем ошибку. Посмотрим состояние сервиса `puma`:
```console
$ systemctl status puma
● puma.service - Puma HTTP Server
   Loaded: loaded (/etc/systemd/system/puma.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 0000-00-00 00:00:00 UTC; 0min 05s ago
 Main PID: 1717 (ruby2.3)
   CGroup: /system.slice/puma.service
           └─1717 puma 3.10.0 (tcp://0.0.0.0:9292) [reddit

Jul 00 00:00:02 bash[1717]: D, [0000-00-00T00:00:02.000000 #1717] DEBUG -- : MONGODB | Connection refused - connect(2) for 51.250.12.230:27017
Jul 00 00:00:04 bash[1717]: D, [0000-00-00T00:00:04.000000 #1717] DEBUG -- : MONGODB | Connection refused - connect(2) for 51.250.12.230:27017
```

Проблема в том, что сервер mongodb по умолчанию слушает локальный интерфейс. Нужно заставить mongodb слушать все доступные интерфейсы, для этого изменим параметр файла конфигурации mongodb с "bind_ip = 127.0.0.1" на "bind_ip = 0.0.0.0". **Важно: в такой конфигурации mongodb использовать нельзя, т.к. он доступен всему миру без аутентификации. Поломають)** Изменим конфигурацию mongodb прямо на сервере, через скрипт `tune_mongodb.sh`:

Содержимое файла `tune_mongodb.sh` модуля `db`:
```bash
#!/bin/sh

sudo sed -i s/127.0.0.1/0.0.0.0/ /etc/mongodb.conf
sudo systemctl restart mongodb
```

Содержимое файла `main.tf` модуля `db`:
```hcl
resource "yandex_compute_instance" "db" {
  name = "reddit-db-${var.environment}"
  zone = var.zone

  labels = {
    tags = "reddit-db-${var.environment}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image_id
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

  provisioner "remote-exec" {
    script = "${path.module}/files/tune_mongodb.sh"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Не забываем добавить переменную `private_key_path` в описание переменных модуля `db` и объявление модуля в основном файле `main.tf`.
Применяем конфигурацию, подключаемся браузером к внешнему адресу сервера приложений, всё работает.


Для того, чтобы можно было управлять деплоем приложения, в зависимости от значения переменной, можно использовать `null_resource`. Добавим переменную `deploy_needed` в описание конфигураций модулей и основной файл конфигурации. Переносим блоки `connection` и `provisioner` в новый ресурс, добавляем `count`, который принимает значения 1 или 0, в зависимости от значения переменой `deploy_needed`. В итоге главный файл модуля `app` будет выглядеть так:
```hcl
resource "yandex_compute_instance" "app" {

  name = "reddit-app-${var.environment}"
  zone = var.zone

  labels = {
    tags = "reddit-app-${var.environment}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "null_resource" "app" {

  count = var.deploy_needed ? 1 : 0

  triggers = {
    app_id = "yandex_compute_instance.app.id"
  }
  connection {
    type        = "ssh"
    host        = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content     = templatefile("${path.module}/files/puma.service.tftpl", { MONGODB_DATABASE_URL = var.database_ip })
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
}
```
По аналогии меняем и модуль `db`. Для активации нового провайдера нужно запустить `terraform init` перед применением конфигурации. Применяем, проверяем, всё работает, как задумано.


**Результат №06-3:**
1. Файлы деплоя перенесли в модули, для ссылок на них используем переменную `${path.module}`
2. В зависимости от значения глобальной булевой переменной `deploy_needed` мы разворачиваем, либо не разворачиваем приложение на создаваемых серверах. Способ реализации - использование `null_resource`.

---

Так, сюрприз, проверка ДЗ падает. Смотрим на результаты тестов - нет папки `modules\vpc`. Чтож, добавим модуль для настройки сети.
Содержимое файла `modules\vpc\main.tf`
```hcl
resource "yandex_vpc_network" "app-network" {
}

resource "yandex_vpc_subnet" "app-subnet" {
  zone           = var.zone
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = var.ipv4_subnet_blocks
}
```

Содержимое файла `modules\vpc\variables.tf`
```hcl
variable "zone" {
  description = "Zone for network creation"
}

variable "ipv4_subnet_blocks" {
  description = "Address blocks for subnet"
}
```

Содержимое файла `modules\vpc\outputs.tf`
```hcl
output "app_subnet_id" {
  value = yandex_vpc_subnet.app-subnet.id
}
```

В основной файл конфигурации добавляем модуль и обновляем переменные:
```hcl
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

module "app" {
  source            = "../modules/app"
  public_key_path   = var.public_key_path
  private_key_path  = var.private_key_path
  app_disk_image_id = var.app_disk_image_id
  subnet_id         = module.subnet.app_subnet_id
  zone              = var.zone
  environment       = var.environment
  database_ip       = module.db.external_ip_address_db
  deploy_needed     = var.deploy_needed
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  db_disk_image_id = var.db_disk_image_id
  subnet_id        = module.subnet.app_subnet_id
  zone             = var.zone
  environment      = var.environment
  deploy_needed    = var.deploy_needed
}

module "subnet" {
  source             = "../modules/vpc"
  zone               = var.zone
  ipv4_subnet_blocks = var.ipv4_subnet_blocks
}
```

Инициализируем модуль и проверяем конфигурацию:
```console
$ terraform get
- subnet in ..\modules\vpc

$ terraform validate
Success! The configuration is valid.
```

Применяем, всё работает.

---

## 07 - Ansible-1

**Задание №07-1:** Знакомство с Ansible, часть 1

**Решение №07-1:**
Исходные данные:
```console
> cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
...

> python3 --version
Python 3.10.4

> ansible --version
ansible 2.10.8

> terraform version
Terraform v0.12.30
```

Создаём новую ветку:
```console
~/r2d2k_infra (main)> git checkout -b ansible-1
Switched to a new branch 'ansible-1'
~/r2d2k_infra (ansible-1)>
```

На базе предыдущего занятия по `terraform` создаём две виртуальные машины, сервер приложений и сервер БД. Работаем в окружении `stage`, через переменную `deploy_needed = false` отключаем установку и настройку приложений. После `terraform apply` получим два внешних адреса.
```console
> terraform apply
...

Outputs:

external_ip_address_app = 51.250.90.126
external_ip_address_db = 51.250.87.190
```

Создаём файл `ansible/inventory`, в нём хранится список серверов и параметры подключения к ним.
```console
> cat inventory
appserver ansible_host=51.250.90.126 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ubuntu
```

Проверяем, что файл создан корректно и у нас есть возможность выполнять команды на удалённом хосте. Один из самых простых модулей `ansible` это `ping`, он отвечает `pong`, если у нас есть доступ к удалённому серверу. Модуль выполняется на удалённом сервере при помощи установленного там `python`.
```console
> ansible -i ./inventory appserver -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Ответ получен, идём дальше. Добавим в `inventory` сервер СУБД.
```console
> cat inventory
appserver ansible_host=51.250.90.126 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ubuntu
dbserver  ansible_host=51.250.87.190 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ubuntu
```

Проверим связь со всеми хостами. **all** - виртуальная группа, содержит все хосты, описанные в `inventory`.
```console
> ansible -i ./inventory all -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Часть параметров можно вынести в файл настроек `ansible.cfg`. Выносим, в `inventory` оставляем только алиасы хостов и их адреса.
```console
> cat ansible.cfg
[defaults]
inventory = ./inventory
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False

> cat inventory
appserver ansible_host=51.250.90.126
dbserver  ansible_host=51.250.87.190

> ansible all -m ping
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Проверим модуль `command`, выполним на удалённых серверах команду `uptime`.
```console
> ansible all -m command -a uptime
appserver | CHANGED | rc=0 >>
 18:33:47 up  1:23,  1 user,  load average: 0.08, 0.02, 0.01
dbserver | CHANGED | rc=0 >>
 18:33:47 up  1:23,  1 user,  load average: 0.00, 0.00, 0.00
```

Для удобства работы можно группировать хосты, создадим две группы `app` и `db`.
```console
> cat inventory
[app]
appserver ansible_host=51.250.90.126

[db]
dbserver  ansible_host=51.250.87.190
```

Проверяем работу.
```console
> ansible app -m command -a uptime
appserver | CHANGED | rc=0 >>
 18:38:07 up  1:27,  1 user,  load average: 0.00, 0.00, 0.00

> ansible db -m ping
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Можно использовать YAML для файлов `inventory`, детали можно посмотреть в [официальной документации](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html). В итоге наш файл `inventory.yaml` примет такой вид:
```yaml
all:
  children:
    app:
      hosts:
        appserver:
          ansible_host: 51.250.90.126
    db:
      hosts:
        dbserver:
          ansible_host: 51.250.87.190
```

В настройках `ansible` укажем новый файл `inventory`:
```console
> cat ansible.cfg
[defaults]
inventory = ./inventory.yaml
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False
```

Напишем простой `playbook` для клонирования репозитория приложения `clone.yaml`:
```yaml
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
```

Выполним его:
```console
> ansible-playbook clone.yaml

PLAY [Clone] ********************************************************************

TASK [Gathering Facts] **********************************************************
ok: [appserver]

TASK [Clone repo] ***************************************************************
fatal: [appserver]: FAILED! => {"changed": false, "msg": "Failed to find required
executable git in paths: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:
/bin:/usr/games:/usr/local/games:/snap/bin"}

PLAY RECAP **********************************************************************
appserver                  : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

Всё сломалось, потому что у нас нет `git` на сервере приложений. Не проблема, установим. Идём на страницу с описанием [модулей](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html), ищем подходящий, читаем описание, добавляем задачу установки `git` с [повышенными привилегиями](https://docs.ansible.com/ansible/latest/user_guide/become.html):
```yaml
- name: Clone
  hosts: app
  tasks:
    - name: Install git package
      ansible.builtin.package:
        name: git
        state: present
      become: yes

    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
```

Проверяем:
```console
> ansible-playbook clone.yaml

PLAY [Clone] *****************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Install git package] ***************************************************************************************
changed: [appserver]

TASK [Clone repo] ************************************************************************************************
ok: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Запускаем второй раз, изменений нет, всё работает, как задумано.
```console
> ansible-playbook clone.yaml

PLAY [Clone] *****************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Install git package] ***************************************************************************************
ok: [appserver]

TASK [Clone repo] ************************************************************************************************
ok: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

В задании нас просят сделать `ansible app -m command -a 'rm -rf ~/reddit'`, затем выполнить `ansible-playbook clone.yaml` и обьяснить результат. Первая команда удалит локальную копию репозитория приложения, которую мы сделали на предыдущем шаге. Запуск второй команды заново получит и сохранит локально копию приложения. Последующие запуски `ansible-playbook clone.yaml` не вызовут никаких изменений, т.к. локальная копия репозитория уже существует на диске.

**Результат №07-1:**
 - Создано локальное окружение для работы с `ansible`
 - Создан статический `inventory` в двух вариантах: обычный текстовый и в формате YAML
 - Проверено выполнение команд на удалённых серверах при помощи различных модулей `ansible`
 - Написан `playbook` для получения локальной копии приложения из удалённого репозитория

---

**Задание №07-2:** Для описания инвентори Ansible использует форматы файлов INI и YAML. Также поддерживается формат JSON. При этом, Ansible поддерживает две различных схемы JSON-inventory: одна является прямым отображением YAML-формата (можно сделать через конвертер YAML <-> JSON), а другая используется для динамического inventory. С небольшими ухищрениями можно заставить Ansible использовать вторую схему и для статических JSON-файлов. Попробуем это сделать...

1. Ознакомьтесь с [Динамическое инвентори в Ansible](https://nklya.medium.com/динамическое-инвентори-в-ansible-9ee880d540d6).
2. Создайте файл inventory.json в формате, описанном в п.1 для нашей ya.cloud-инфраструктуры и скрипт для работы с ним.
3. Добейтесь успешного выполнения команды ansible all -m ping и опишите шаги в README.
4. Добавьте параметры в файл ansible.cfg для работы с инвентори в формате JSON.
5. Если вы разобрались с отличиями схем JSON для динамического и статического инвентори, также добавьте описание в README

**Решение №07-2:**

Динамическое инвентори - это скрипт, который добывает информацию о хостах из какого-то источника и отдаёт её в формате JSON. При запуске с параметром `--list` скрипт должен вернуть список хостов с их параметрами. При запуске с параметром `--host <hostname>` скрипт может вернуть параметры этого хоста, ну или вернуть пустой список.

Наш исходный файл инвентори выглядит так:
```yaml
all:
  children:
    app:
      hosts:
        appserver:
          ansible_host: 51.250.90.126
    db:
      hosts:
        dbserver:
          ansible_host: 51.250.87.190
```

Если мы переведём его в формат JSON, то получим `inventory.json`:
```json
{
    "all": {
        "children": {
            "app": {
                "hosts": {
                    "appserver": {
                        "ansible_host": "51.250.90.126"
                    }
                }
            },
            "db": {
                "hosts": {
                    "dbserver": {
                        "ansible_host": "51.250.87.190"
                    }
                }
            }
        }
    }
}
```

Тестовый запуск c инвентори такого формата проходит успешно:
```console
> ansible -i ./inventory.json all -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Читаем [описание](https://nklya.medium.com/динамическое-инвентори-в-ansible-9ee880d540d6) динамического инвентори, видим, что он должен вернуть список хостов и блок `_meta`, в котором указаны переменные хостов. Для теста подготовим источник данных для скрипта динамического инвентори `inventory-src.json`:
```json
{
    "app": {
        "hosts": ["appserver"]
    },
    "db": {
        "hosts": ["dbserver"]
    },
    "_meta": {
        "hostvars": {
            "appserver": {
                "ansible_host": "51.250.90.126"
            },
            "dbserver": {
                "ansible_host": "51.250.87.190"
            }
        }
    }
}
```

_Из статического инвентори можно получить внутреннее представление при помощи `ansible-inventory -i ./inventory --list`._

Подготовим простой скрипт, который будет скармливать `ansible` сформированный нами файл. Обрабатывать входные параметры не будем, наша основная цель - проверить теорию на практике.

Содержимое скрипта `inventory-dyn.sh`:
```sh
#!/bin/sh

cat inventory-src.json
```

Делаем файл исполняемым `chmod +x inventory-dyn.sh` и проверяем работу "динамического" инвентори:
```console
> ansible -i ./inventory-dyn.sh all -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Меняем конфигурацию `ansible.cgf`, прописываем в качестве инвентори наш скрипт:
```ini
[defaults]
inventory = ./inventory-dyn.sh
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False
```

Проверяем работу, запускаем `ansible` без указания инвентори:
```console
> ansible all -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Playbook тоже отрабатывает без ошибок:
```console
> ansible-playbook clone.yaml

PLAY [Clone] *****************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Install git package] ***************************************************************************************
ok: [appserver]

TASK [Clone repo] ************************************************************************************************
ok: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

**Результат №07-2:**
Разобран формат динамического инвентори, подготовлен скрипт для работы с ним. Пробные запуски `ansible` отрабатывают, как положено.

---

Формально задание выполнено, но попробуем генерировать файл инвентори напрямую из "облака". Для этого нам нужно:
1. Выбрать язык программирования
2. Разобраться с API Yandex Cloud
3. Авторизоваться в облаке
4. Получить список запущеных машин, их имена, внешние IP адреса
5. Сформировать JSON и вывести его на STDOUT
6. Опционально: обрабатывать параметры `--list` и `--host <hostname>`

Язык программирования: выберу `python`. Основная причина - хост, на котором мы работаем, уже подготовлен к работе с `python`, на нём `ansible` написан) Вторая причина - популярность этого языка.

Разобраться с API: идём, изучаем [документацию на облако](https://cloud.yandex.com/ru-ru/docs).

Для использования API надо авторизоваться, подробности можно узнать [тут](https://cloud.yandex.ru/docs/resource-manager/api-ref/authentication). Если кратко, то нам нужно получить IAM токен и передавать его в заголовках при обращению к облаку. Получить IAM токен можно [в обмен на JWT](https://cloud.yandex.ru/docs/iam/operations/iam-token/create-for-sa#via-jwt). Для получения JWT нужен сервисный аккаунт, заведём его для `ansible` и получим ключ.

Идём в консоль облака, раздел "сервисные аккаунты", добавляем аккаунт `yc-ansible` с ролью `viewer`. После создания аккаунта генерируем для него ключ `yc iam key create --service-account-name yc-ansible --output ansible-key.json`.

После некоторого количества экспериментов с API получим скрипт `yc_inventory.py`:
```python
#!/usr/bin/env python3
#
# Скрипт написан в учебных целях, содержит ряд допущений
# Скрипт не принимает и не обрабатывает параметры командной строки
# Для работы скрипта нужно указать ниже параметры folder_id и sa_key_filename
# Группы хостов создаются из тегов хоста, т.е. у хоста должен быть только один тег и он должен быть задан в виде строки
# У каждого из хостов должен быть хотя бы один внешний IP адрес
#

import json
from urllib import response
import requests
import jwt
import time

# Блок переменных, меняем на свои значения
folder_id = '******************pp'
sa_key_filename = 'ansible-key.json'

# Адреса Яндекса, не трогаем
url_compute_instances = 'https://compute.api.cloud.yandex.net/compute/v1/instances'
url_iam_tokens = 'https://iam.api.cloud.yandex.net/iam/v1/tokens'

# Чиитаем из файла ключа параметры для создания JWT
with open(sa_key_filename) as sa_key_file:
  sa_key = json.load(sa_key_file)

# Готовим данные для JWT
now = int(time.time())

payload = {
  'aud': url_iam_tokens,
  'iss': sa_key['service_account_id'],
  'iat': now,
  'exp': now + 360
}

encoded_token = jwt.encode(
  payload,
  sa_key['private_key'],
  algorithm = 'PS256',
  headers = {'kid': sa_key['id']}
)

# JWT готов
payload = {'jwt': encoded_token}

# Запрашиваем IAM токен
req = requests.post(url_iam_tokens, json = payload)
iam_token = req.json()['iamToken']

# Используя IAM токен получаем список машин
payload = {'folder_id': folder_id}
headers = {'Authorization': 'Bearer ' + iam_token}
req = requests.get(url_compute_instances, json = payload, headers = headers)
response_json = req.json()

# Оформляем inventory
inventory = {}
inventory['_meta'] = {}
inventory['_meta']['hostvars'] = {}

for instance in response_json['instances']:
    i_name = instance['name']
    i_fqdn = instance['fqdn']
    i_group = instance['labels']['tags']
    i_ext_ip = instance['networkInterfaces'][0]['primaryV4Address']['oneToOneNat']['address']
    ansible_vars = {}
    ansible_vars['ansible_host'] = i_ext_ip
    inventory['_meta']['hostvars'][i_fqdn] = ansible_vars
    if not i_group in inventory:
        inventory[i_group] = {}
        inventory[i_group]['hosts'] = []
        inventory[i_group]['hosts'].append(i_fqdn)
    else:
        inventory[i_group]['hosts'].append(i_fqdn)

# Выводим инвентори в формате JSON
print(json.dumps(inventory, indent=4))
```

Проверим его работу:
```console
> ansible-inventory -i ./yc-inventory.py --list
{
    "_meta": {
        "hostvars": {
            "fhm24rj8n23dod80i4in.auto.internal": {
                "ansible_host": "51.250.90.126"
            },
            "fhmupp78em66421ll9g7.auto.internal": {
                "ansible_host": "51.250.87.190"
            }
        }
    },
    "all": {
        "children": [
            "reddit-app-stage",
            "reddit-db-stage",
            "ungrouped"
        ]
    },
    "reddit-app-stage": {
        "hosts": [
            "fhm24rj8n23dod80i4in.auto.internal"
        ]
    },
    "reddit-db-stage": {
        "hosts": [
            "fhmupp78em66421ll9g7.auto.internal"
        ]
    }
}
```

Обновляем конфигурацию `ansible.cfg`, указываем наш скрипт:
```ini
[defaults]
inventory = ./yc-inventory.py
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False
```

Проверяем работу:
```console
> ansible all -m ping
fhm24rj8n23dod80i4in.auto.internal | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
fhmupp78em66421ll9g7.auto.internal | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Всё работает.

---

## 08 - Ansible-2

**Задание №08-1:** Знакомство с Ansible, часть 2

**Решение №08-1:**

Исходные данные:
```console
> cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
...

> python3 --version
Python 3.10.4

>python2 --version
Python 2.7.18

> ansible --version
ansible 2.6.0

> terraform version
Terraform v0.12.30
+ provider.null v3.1.0
+ provider.yandex v0.56.0
...
```

Создаём новую ветку:
```console
> git checkout -b ansible-2
Switched to a new branch 'ansible-2'
```

На базе предыдущего занятия по `terraform` создаём две виртуальные машины, сервер приложений и сервер БД. Работаем в окружении `stage`, через переменную `deploy_needed = false` отключаем установку и настройку приложений. После `terraform apply` получим два внешних адреса.
```console
> terraform apply
...

Outputs:

external_ip_address_app = 51.250.81.11
external_ip_address_db = 51.250.92.226
```

В метки хостов модулей `app`, `db` добавим `group`, по ней будем строить динамический инвентори, разносить хосты по группам. Изменения внесём такие:
```diff
diff --git a/ansible/yc-inventory.py b/ansible/yc-inventory.py
--- a/ansible/yc-inventory.py
+++ b/ansible/yc-inventory.py
@@ -3,7 +3,7 @@
 # Скрипт написан в учебных целях, содержит ряд допущений
 # Скрипт не принимает и не обрабатывает параметры командной строки
 # Для работы скрипта нужно указать ниже параметры folder_id и sa_key_filename
-# Группы хостов создаются из тегов хоста, т.е. у хоста должен быть только один тег и он должен быть задан в виде строки
+# Группы хостов создаются из меток хоста, т.е. у хоста должна быть метка group и она должна быть задана в виде строки
 # У каждого из хостов должен быть хотя бы один внешний IP адрес
 #

@@ -63,7 +63,7 @@ inventory['_meta']['hostvars'] = {}
 for instance in response_json['instances']:
     i_name = instance['name']
     i_fqdn = instance['fqdn']
-    i_group = instance['labels']['tags']
+    i_group = instance['labels']['group']
     i_ext_ip = instance['networkInterfaces'][0]['primaryV4Address']['oneToOneNat']['address']
     ansible_vars = {}
     ansible_vars['ansible_host'] = i_ext_ip
```

Проверим работу:
```console
> ansible all -m ping
fhmrhv3n23sc6dfm30t3.auto.internal | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to 51.250.81.11 closed.\r\n",
    "module_stdout": "/bin/sh: 1: /usr/bin/python: not found\r\n",
    "msg": "MODULE FAILURE",
    "rc": 127
}
fhmea26pati7cb4lckmd.auto.internal | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to 51.250.92.226 closed.\r\n",
    "module_stdout": "/bin/sh: 1: /usr/bin/python: not found\r\n",
    "msg": "MODULE FAILURE",
    "rc": 127
}
```

На удалённых машинах не `python`, работать ничего не будет. У нас два варианта - обновить исходные образы, добавив в них нужные пакеты, либо установить `python` при помощи `ansible`. Напишем короткий `install_python.yml`:
```yaml
- name: Install Python
  hosts: all
  gather_facts: no

  tasks:
    - name: Install Pyhon use raw module
      raw: apt install -y python
      become: yes
```

Применяем:
```console
> ansible-playbook install_python.yml
PLAY [Install Python] *************************************************************

TASK [Install Pyhon use raw module] ***********************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]
changed: [fhmea26pati7cb4lckmd.auto.internal]

PLAY RECAP ************************************************************************
fhmea26pati7cb4lckmd.auto.internal : ok=1    changed=1    unreachable=0    failed=0
fhmrhv3n23sc6dfm30t3.auto.internal : ok=1    changed=1    unreachable=0    failed=0
```

Проверяем связь:
```console
> ansible all -m ping
fhmrhv3n23sc6dfm30t3.auto.internal | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
fhmea26pati7cb4lckmd.auto.internal | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Создаём `reddit_app.yml` для настройки MongoDB:
```yaml
- name: Configure hosts & deploy application
  hosts: db

  tasks:
    - name: Change mongo config file
      become: true
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      tags: db-tag
```

И шаблон `templates/mongodb.conf.j2` к нему
```yaml
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongodb.log

# network interfaces
net:
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }}
```

Проверяем:
```console
> ansible-playbook reddit_app.yml --check

PLAY [Configure hosts & deploy application] *******************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************
ok: [fhmea26pati7cb4lckmd.auto.internal]

TASK [Change mongo config file] *******************************************************************************************************************************
fatal: [fhmea26pati7cb4lckmd.auto.internal]: FAILED! => {"changed": false, "msg": "AnsibleUndefinedVariable: 'mongo_bind_ip' is undefined"}

PLAY RECAP *******************************************************************************************************************************
fhmea26pati7cb4lckmd.auto.internal : ok=1    changed=0    unreachable=0    failed=1
```

Не хватает переменных. Добавим:
```yaml
- name: Configure hosts & deploy application
  hosts: db
  vars:
    mongo_bind_ip: 0.0.0.0

  tasks:
    - name: Change mongodb config file
      become: true
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      tags: db-tag
```

Проверяем:
```console
> ansible-playbook reddit_app.yml --check --limit db


PLAY [Configure hosts & deploy application] ***************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmea26pati7cb4lckmd.auto.internal]

TASK [Change mongo config file] ***************************************************
changed: [fhmea26pati7cb4lckmd.auto.internal]

PLAY RECAP ************************************************************************
fhmea26pati7cb4lckmd.auto.internal : ok=2    changed=1    unreachable=0    failed=0
```

Всё в порядке. Можем применять:
```console
> ansible-playbook reddit_app.yml --limit db
PLAY [Configure hosts & deploy application] ***************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmea26pati7cb4lckmd.auto.internal]

TASK [Change mongodb config file] *************************************************
changed: [fhmea26pati7cb4lckmd.auto.internal]

RUNNING HANDLER [restart mongodb] *************************************************
changed: [fhmea26pati7cb4lckmd.auto.internal]

PLAY RECAP ************************************************************************
fhmea26pati7cb4lckmd.auto.internal : ok=3    changed=2    unreachable=0    failed=0
```

Проверим, что у нас на хосте `db`:
```console
ubuntu@fhmea26pati7cb4lckmd:~$ ss -nlp4
Netid State      Recv-Q Send-Q Local Address:Port               Peer Address:Port
udp   UNCONN     0      0            *:68                       *:*
udp   UNCONN     0      0            *:68                       *:*
tcp   LISTEN     0      128          *:27017                    *:*
tcp   LISTEN     0      128          *:22                       *:*
```

Настройки применены, сервис `mongodb` прослушивает все интерфейсы.
Займёмся настройкой приложения, создаём `files/puma.service`:
```ini
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/ubuntu/db_config
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

Обновим файл `reddit_app.yml`:
```yaml
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
    db_host: 192.168.10.19

  tasks:
    - name: Change mongodb config file
      become: true
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      tags: db-tag
      notify: restart mongodb

    - name: Add unit file for Puma
      become: true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
      tags: app-tag

    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag

  handlers:
    - name: restart mongodb
      service: name=mongodb state=restarted
      become: true

    - name: reload puma
      service: name=puma state=restarted
      become: true
```

Добавим файл шаблона переменной окружения `templates/db_config.j2`:
```yaml
DATABASE_URL={{ db_host }}
```

Применяем:
```console
> ansible-playbook reddit_app.yml --limit app --tags app-tag

PLAY [Configure hosts & deploy application] ***************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmrhv3n23sc6dfm30t3.auto.internal]

TASK [Add unit file for Puma] *****************************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

TASK [Add config for DB connection] ***********************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

TASK [enable puma] ****************************************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

RUNNING HANDLER [reload puma] *****************************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

PLAY RECAP ************************************************************************
fhmrhv3n23sc6dfm30t3.auto.internal : ok=5    changed=4    unreachable=0    failed=0
```

Работает. Добавляем обновление исходников приложения из репозитория + устанавливаем сам `git`:
```yaml
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
    db_host: 192.168.10.19

  tasks:
    - name: Install git
      become: true
      apt:
        name: git
        state: present
      tags: deploy-tag

    - name: Change mongodb config file
      become: true
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      tags: db-tag
      notify: restart mongodb

    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      tags: deploy-tag
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      tags: deploy-tag

    - name: Add unit file for Puma
      become: true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
      tags: app-tag

    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag

  handlers:
    - name: restart mongodb
      service: name=mongodb state=restarted
      become: true

    - name: reload puma
      service: name=puma state=restarted
      become: true
```

Проверяем:
```console
> ansible-playbook reddit_app.yml --limit app --tags deploy-tag

PLAY [Configure hosts & deploy application] ***************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmrhv3n23sc6dfm30t3.auto.internal]

TASK [Install git] ****************************************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

TASK [Fetch the latest version of application code] *******************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

TASK [Bundle install] *************************************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

RUNNING HANDLER [reload puma] *****************************************************
changed: [fhmrhv3n23sc6dfm30t3.auto.internal]

PLAY RECAP ************************************************************************
fhmrhv3n23sc6dfm30t3.auto.internal : ok=5    changed=4    unreachable=0    failed=0
```

Всё работает, приложение доступно по адресу http://51.250.81.11:9292/.

---

Удаляем инфраструктуру `terraform destroy`, создаём заново `terraform apply`:
```console
...
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 51.250.94.103
external_ip_address_db = 51.250.92.226
```

Устанавливаем `python` на машины: `ansible-playbook install_python.yml`.
Переписываем playbook, делим его на две части: настройка сервера БД и настройка сервера приложений, сохраняем в `reddit_app2.yml`.
```yaml
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongodb config file
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      notify: restart mongodb

  handlers:
  - name: restart mongodb
    service: name=mongodb state=restarted

- name: Configure App
  hosts: app
  tags: app-tag
  become: true
  vars:
   db_host: 51.250.92.226
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted

- name: Deploy App
  hosts: app
  tags: deploy-tag
  become: true
  tasks:
    - name: Install git
      apt:
        name: git
        state: present

    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      notify: reload puma

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```

Проверяем поочерёдно:
- `ansible-playbook reddit_app2.yml --tags db-tag --check`
- `ansible-playbook reddit_app2.yml --tags db-tag`
- `ansible-playbook reddit_app2.yml --tags app-tag --check`
- `ansible-playbook reddit_app2.yml --tags app-tag`
- `ansible-playbook reddit_app2.yml --tags deploy-tag --check`
- `ansible-playbook reddit_app2.yml --tags deploy-tag`

Проверяем приложение - всё работает.

---

Делим наш playbook на отдельные файлы.
Содержимое `app.yml`:
```yaml
- name: Configure App
  hosts: app
  become: true
  vars:
   db_host: 51.250.92.226
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```

Содержимое `db.yml`:
```yaml
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongodb config file
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      notify: restart mongodb

  handlers:
  - name: restart mongodb
    service: name=mongodb state=restarted
```

Содержимое `deploy.yml`:
```yaml
- name: Deploy App
  hosts: app
  become: true
  tasks:
    - name: Install git
      apt:
        name: git
        state: present

    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      notify: reload puma

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```

Объединим все три файла в один `site.yml`:
```yaml
- import_playbook: install_python.yml
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```

Удаляем инфраструктуру `terraform destroy`, создаём заново `terraform apply`:
```console
...
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 51.250.92.123
external_ip_address_db = 51.250.94.221
```

Обновляем переменную `db_host` в `app.yml`, проверяем `ansible-playbook site.yml --check`, запускаем `ansible-playbook site.yml`:
```console
> ansible-playbook site.yml
PLAY [Install Python] *************************************************************

TASK [Install Pyhon use raw module] ***********************************************
changed: [fhmckjssuf6p608vas5u.auto.internal]
changed: [fhmj1hed13lv03jtck88.auto.internal]

PLAY [Configure MongoDB] **********************************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmckjssuf6p608vas5u.auto.internal]

TASK [Change mongodb config file] *************************************************
changed: [fhmckjssuf6p608vas5u.auto.internal]

RUNNING HANDLER [restart mongodb] *************************************************
changed: [fhmckjssuf6p608vas5u.auto.internal]

PLAY [Configure App] **************************************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmj1hed13lv03jtck88.auto.internal]

TASK [Add unit file for Puma] *****************************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

TASK [Add config for DB connection] ***********************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

TASK [enable puma] ****************************************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

RUNNING HANDLER [reload puma] *****************************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

PLAY [Deploy App] *****************************************************************

TASK [Gathering Facts] ************************************************************
ok: [fhmj1hed13lv03jtck88.auto.internal]

TASK [Install git] ****************************************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

TASK [Fetch the latest version of application code] *******************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

TASK [Bundle install] *************************************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

RUNNING HANDLER [reload puma] *****************************************************
changed: [fhmj1hed13lv03jtck88.auto.internal]

PLAY RECAP ************************************************************************
fhmckjssuf6p608vas5u.auto.internal : ok=4    changed=3    unreachable=0    failed=0
fhmj1hed13lv03jtck88.auto.internal : ok=11   changed=9    unreachable=0    failed=0
```

**Результат №08-1:**

Ошибок нет, всё работает, приложение доступно по внешнему адресу http://51.250.92.123:9292/. Завидная повторяемость)

---

**Задание №08-2:**
Ansible на текущий момент (07.2020) из коробки не умеет динамическую инвентаризацию в Yandex.Cloud. Нам нужно писать свои костыли, как в предыдущем ДЗ. Но если порыскать по репозиторию, то можно натолкнуться на вот [PR](https://github.com/ansible/ansible/pull/61722). Попробуйте использовать это решение для инвентаризации.

**Решение №08-2:**
Идём по ссылке, видим, что кто-то уже предложил вариант динамического инвентори, которое работает напрямую с облаком. Я случайно написал подобный скрипт в прошлом задании, но раз просят использовать этот PR, то попробуем разобраться с ним.

Смотрим, откуда приехал этот PR, клонируем его себе локально с указанием ветки: `git clone --branch yc_compute https://github.com/st8f/community.general.git`. Сам плагин находим тут: `community.general/plugins/inventory/yc_compute.py`. Читаем, изучаем. Параллельно изучаем документацию по [inventory plugins](https://docs.ansible.com/ansible/latest/plugins/inventory.html).

Чтобы подключить плагин, нужно добавить его в `ansible.cfg`:
```ini
...
[inventory]
enable_plugins = yc_compute
...
```

Проверяем:
```console
> ansible-inventory --list
 [WARNING]: Failed to load inventory plugin, skipping yc_compute
```

Правильно, плагина нет в поставке. Добавим руками. Проверяем место размещения плагинов инвентори:
```console
> ansible-config dump | grep inventory
DEFAULT_INVENTORY_PLUGIN_PATH(default) = [u'/home/ubuntu/.ansible/plugins/inventory', u'/usr/share/ansible/plugins/inventory']
VARIABLE_PRECEDENCE(default) = ['all_inventory', 'groups_inventory', 'all_plugins_inventory', 'all_plugins_play', 'groups_plugins_inventory', 'groups_plugins_play']
```

На моей машине плагины инвентори лежат по пути `/home/ubuntu/.ansible/plugins/inventory`, закинем туда наш `yc_compute.py` из ранее клонированного репозитория.
Проверяем:
```console
> ansible-inventory --list
ERROR! Import error for yandex.cloud SDK. Please install "yandexcloud" package to your environment.
```

_Тут я получил проблемы с python27. В итоге удалил ansible, зачистил систему от python27, установил свежий ansible и python310 с пакетом python3-pip._

Просят установить Yandex.SDK, сделаем это: `pip3 install yandexcloud`. После проверим работу инвентори:
```console
> ansible-inventory --list
[WARNING]: Unable to parse /home/ubuntu/r2d2k_infra/ansible/inventory.yml as an inventory source
[WARNING]: No inventory was parsed, only implicit localhost is available
{
    "_meta": {
        "hostvars": {}
    },
    "all": {
        "children": [
            "ungrouped"
        ]
    }
}
```

Ничего не выходит, пора читать документацию и для этого в ansible есть свой способ. Для начала проверяем список доступных плагинов инвентори:

```console
> ansible-doc -t inventory --list
advanced_host_list                   Parses a 'host list' with ranges
amazon.aws.aws_ec2                   EC2 inventory source
amazon.aws.aws_rds                   rds instance source
auto                                 Loads and executes an inventory plugin specified in a YAML config
awx.awx.tower                        Ansible dynamic inventory plugin for Ansible Tower
azure.azcollection.azure_rm          Azure Resource Manager inventory plugin
cloudscale_ch.cloud.inventory        cloudscale.ch inventory source
community.docker.docker_containers   Ansible dynamic inventory plugin for Docker containers
community.docker.docker_machine      Docker Machine inventory source
community.docker.docker_swarm        Ansible dynamic inventory plugin for Docker swarm nodes
community.general.cobbler            Cobbler inventory source
community.general.docker_machine     Docker Machine inventory source
community.general.docker_swarm       Ansible dynamic inventory plugin for Docker swarm nodes
community.general.gitlab_runners     Ansible dynamic inventory plugin for GitLab runners
community.general.kubevirt           KubeVirt inventory source
community.general.linode             Ansible dynamic inventory plugin for Linode
community.general.nmap               Uses nmap to find hosts to target
community.general.online             Scaleway (previously Online SAS or Online.net) inventory source
community.general.proxmox            Proxmox inventory source
community.general.scaleway           Scaleway inventory source
community.general.stackpath_compute  StackPath Edge Computing inventory source
community.general.virtualbox         virtualbox inventory source
community.hrobot.robot               Hetzner Robot inventory source
community.kubernetes.k8s             Kubernetes (K8s) inventory source
community.kubernetes.openshift       OpenShift inventory source
community.kubevirt.kubevirt          KubeVirt inventory source
community.libvirt.libvirt            Libvirt inventory source
community.okd.openshift              OpenShift inventory source
community.vmware.vmware_vm_inventory VMware Guest inventory source
constructed                          Uses Jinja2 to construct vars and groups based on existing inventory
generator                            Uses Jinja2 to construct hosts and groups from patterns
google.cloud.gcp_compute             Google Cloud Compute Engine inventory source
hetzner.hcloud.hcloud                Ansible dynamic inventory plugin for the Hetzner Cloud
host_list                            Parses a 'host list' string
ini                                  Uses an Ansible INI file as inventory source
netbox.netbox.nb_inventory           NetBox inventory source
ngine_io.vultr.vultr                 Vultr inventory source
openstack.cloud.openstack            OpenStack inventory source
ovirt.ovirt.ovirt                    oVirt inventory source
script                               Executes an inventory script that returns JSON
servicenow.servicenow.now            ServiceNow Inventory Plugin
theforeman.foreman.foreman           Foreman inventory source
toml                                 Uses a specific TOML file as an inventory source
yaml                                 Uses a specific YAML file as an inventory source
yc_compute                           Yandex.Cloud Compute inventory source
```

Нас интересует последний плагин. Запрашиваем по нему подробности:

```console
> ansible-doc -t inventory yc_compute
> YC_COMPUTE    (/home/ubuntu/.ansible/plugins/inventory/yc_compute.py)

        Pull inventory from Yandex Cloud Compute. Uses a YAML configuration file that ends with yc_compute.(yml|yaml) or
        yc.(yml|yaml).

OPTIONS (= is mandatory):

- api_retry_count
        Retries count for API calls.
        [Default: 5]
        type: int

= auth_kind
        The type of credential used.
        (Choices: oauth, serviceaccountfile)
        set_via:
          env:
          - name: YC_ANSIBLE_AUTH_KIND

        type: string

- cache
        Toggle to enable/disable the caching of the inventory's source data, requires a cache plugin setup to work.
        [Default: False]
        set_via:
          env:
          - name: ANSIBLE_INVENTORY_CACHE
          ini:
          - key: cache
            section: inventory

        type: bool

- cache_connection
        Cache connection data or path, read cache plugin documentation for specifics.
        [Default: (null)]
        set_via:
          env:
          - name: ANSIBLE_CACHE_PLUGIN_CONNECTION
          - name: ANSIBLE_INVENTORY_CACHE_CONNECTION
          ini:
          - key: fact_caching_connection
            section: defaults
          - key: cache_connection
            section: inventory

        type: str

- cache_plugin
        Cache plugin to use for the inventory's source data.
        [Default: memory]
        set_via:
          env:
          - name: ANSIBLE_CACHE_PLUGIN
          - name: ANSIBLE_INVENTORY_CACHE_PLUGIN
          ini:
          - key: fact_caching
            section: defaults
          - key: cache_plugin
            section: inventory

        type: str

- cache_prefix
        Prefix to use for cache plugin files/tables
        [Default: ansible_inventory_]
        set_via:
          env:
          - name: ANSIBLE_CACHE_PLUGIN_PREFIX
          - name: ANSIBLE_INVENTORY_CACHE_PLUGIN_PREFIX
          ini:
          - key: fact_caching_prefix
            section: default
          - key: cache_prefix
            section: inventory


- cache_timeout
        Cache duration in seconds
        [Default: 3600]
        set_via:
          env:
          - name: ANSIBLE_CACHE_PLUGIN_TIMEOUT
          - name: ANSIBLE_INVENTORY_CACHE_TIMEOUT
          ini:
          - key: fact_caching_timeout
            section: defaults
          - key: cache_timeout
            section: inventory

        type: int

- compose
        Create vars from jinja2 expressions.
        [Default: {}]
        type: dict

- filters
        List of jinja2 expressions to perform client-side hosts filtering.
        Possible fields are described here https://cloud.yandex.com/docs/compute/api-ref/Instance/list.
        When overriding this option don't forget to explicitly include default value to your rules (if you need it).
        [Default: status == 'RUNNING']
        type: list

= folders
        List of Yandex.Cloud folder ID's to list instances from.

        type: list

- groups
        Add hosts to group based on Jinja2 conditionals.
        [Default: {}]
        type: dict

- hostnames
        The list of methods for determining the hostname.
        Several methods can be tried one by one. Until successful hostname detection.
        Currently supported methods are 'public_ip', 'private_ip' and 'fqdn'.
        Any other value is parsed as a jinja2 expression.
        [Default: ['public_ip', 'private_ip', 'fqdn']]
        type: list

- keyed_groups
        Add hosts to group based on the values of a variable.
        [Default: []]
        type: list

- oauth_token
        OAUTH token string. See https://cloud.yandex.com/docs/iam/concepts/authorization/oauth-token.
        [Default: (null)]
        set_via:
          env:
          - name: YC_ANSIBLE_OAUTH_TOKEN

        type: string

= plugin
        The name of this plugin, it should always be set to `community.general.yc_compute' for this plugin to recognize it as it's
        own.
        (Choices: community.general.yc_compute)
        type: str

- remote_filter
        Sets `filter' parameter for `list' API call.
        Currently you can use filtering only on the Instance.name field.
        See https://cloud.yandex.com/docs/compute/api-ref/Instance/list.
        Use `filters' option for more flexible client-side filtering.
        [Default: (null)]
        type: string

- service_account_contents
        Similar to service_account_file. Should contain raw contents of the Service Account JSON file.
        [Default: (null)]
        set_via:
          env:
          - name: YC_ANSIBLE_SERVICE_ACCOUNT_CONTENTS

        type: string

- service_account_file
        The path of a Service Account JSON file. Must be set if auth_kind is "serviceaccountfile".
        Service Account JSON file can be created by `yc' tool:
        `yc iam key create --service-account-name my_service_account --output my_service_account.json'
        [Default: (null)]
        set_via:
          env:
          - name: YC_ANSIBLE_SERVICE_ACCOUNT_FILE

        type: path

- strict
        If `yes' make invalid entries a fatal error, otherwise skip and continue.
        Since it is possible to use facts in the expressions they might not always be available and we ignore those errors by
        default.
        [Default: False]
        type: bool


REQUIREMENTS:  yandexcloud==0.10.1

NAME: yc_compute

PLUGIN_TYPE: inventory

EXAMPLES:

plugin: community.general.yc_compute
folders:  # List inventory hosts from these folders.
  - <your_folder_id>
filters:
  - status == 'RUNNING'
  - labels['role'] == 'db'
auth_kind: serviceaccountfile
service_account_file: /path/to/your/service/account/file.json
hostnames:
  - fqdn  # Use FQDN for inventory hostnames.
# You can also format hostnames with jinja2 expressions like this
# - "{{id}}_{{name}}"

compose:
  # Set ansible_host to the Public IP address to connect to the host.
  # For Private IP use "network_interfaces[0].primary_v4_address.address".
  ansible_host: network_interfaces[0].primary_v4_address.one_to_one_nat.address

keyed_groups:
  # Place hosts in groups named by folder_id.
  - key: folder_id
    prefix: ''
    separator: ''
  # Place hosts in groups named by value of labels['group'].
  - key: labels['group']

groups:
  # Place hosts in 'ssd' group if they have appropriate disk_type label.
  ssd: labels['disk_type'] == 'ssd'
```

Видим, что плагин конфигурируется через YAML файл, условие - он должен оканчиваться на yc_compute.(yml|yaml) или на yc.(yml|yaml). Обязательные опции указаны знаком '='. Готовим файл `yc.yml`:
```yaml
plugin: yc_compute

folders:
  - ******************pp

auth_kind: serviceaccountfile

service_account_file: ./ansible-key.json

hostnames:
  - fqdn

compose:
  ansible_host: network_interfaces[0].primary_v4_address.one_to_one_nat.address

keyed_groups:
  - key: labels['group']
    prefix: ''
    separator: ''
```

Заметка про `keyed_groups`: группы хостов создаём на основании меток у виртуальных машин, в нашем случае - метка `group` формирует имя группы хостов.

Прописываем его в конфигурации `ansible.cfg`:
```ini
[defaults]
inventory = ./yc.yml
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False

[inventory]
enable_plugins = yc_compute
```

Проверяем работу `ansible-inventory --list`:
```json
{
    "_app": {
        "hosts": [
            "fhmj1hed13lv03jtck88.auto.internal"
        ]
    },
    "_db": {
        "hosts": [
            "fhmckjssuf6p608vas5u.auto.internal"
        ]
    },
    "_meta": {
        "hostvars": {
            "fhmckjssuf6p608vas5u.auto.internal": {
                "ansible_host": "51.250.94.221"
            },
            "fhmj1hed13lv03jtck88.auto.internal": {
                "ansible_host": "51.250.92.123"
            }
        }
    },
    "all": {
        "children": [
            "_app",
            "_db",
            "ungrouped"
        ]
    }
}
```

**Результат №08-2:**
Мы добыли из репозитория плагин для динамического инвентори Yandex.Cloud, подключили его, установили зависимости, создали файл конфигурации.
Всё работает.

---

**Задание №08-3:**
1. Заменить скрипты, используемые `packer` на плэйбуки `ansible`.
2. Заменить скрипты в секциях `provisioners` файлов конфигурации `packer` на `ansible`.


**Решение №08-3:**
Плэйбук `packer_app.yml` для установки `ruby` и `bundler` будет выглядеть так:
```yaml
- name: Install base for application deploy
  hosts: all
  become: true
  tasks:
    - name: Install packages for app base
      apt:
        name: ['apt-transport-https', 'ca-certificates', 'ruby-full', 'ruby-bundler', 'build-essential', 'git']
        state: present
        update_cache: yes
      retries: 5
      delay: 20

    - name: Remove useless packages from the cache
      apt:
        autoclean: yes

    - name: Remove dependencies that are no longer required
      apt:
        autoremove: yes
```

Подключать репозитории мы не будем, т.к. есть проблемы с доступом к ним. При желании можно почитать документацию на [apt_key](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_key_module.html) и [apt_repository](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_repository_module.html).
Плэйбук `packer_db.yml` для установки `mongodb` и включения сервиса будет выглядеть так:
```yaml
- name: Install base for database server
  hosts: all
  become: true
  tasks:
    - name: Install mongodb
      apt:
        name: mongodb
        state: present
        update_cache: yes
      retries: 5
      delay: 20

    - name: Remove useless packages from the cache
      apt:
        autoclean: yes

    - name: Remove dependencies that are no longer required
      apt:
        autoremove: yes

    - name: Enable mongodb service
      systemd:
        name: mongodb
        enabled: yes
```

Заменим `provisioners` с `shell` на `ansible`.
Без указания `"use_proxy": false` сборка образа падала с такой ошибкой:
```console
    yandex: fatal: [default]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Unable to negotiate with 127.0.0.1 port 46297: no matching host key type found. Their offer: ssh-rsa", "unreachable": true}
```

Содержимое `packer/app.json`:
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
            "image_name": "reddit-app-{{timestamp}}",
            "image_family": "reddit-app",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "use_proxy": false,
            "playbook_file": "ansible/packer_app.yml"
        }
    ]
}
```

Содержимое `packer/db.json`:
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
            "image_name": "reddit-db-{{timestamp}}",
            "image_family": "reddit-db",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "use_proxy": false,
            "playbook_file": "ansible/packer_db.yml"
        }
    ]
}
```

Командой `packer build -var-file=./packer/variables.json ./packer/app.json` собираем образ:
```console
yandex: output will be in this color.

==> yandex: Creating temporary RSA SSH key for instance...
==> yandex: Using as source image: fd88e9eo161152ui8uji (name: "ubuntu-16-04-lts-v20220711", family: "ubuntu-1604-lts")
==> yandex: Creating network...
==> yandex: Creating subnet in zone "ru-central1-a"...
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmrl623o75f5heuarqh to become active...
    yandex: Detected instance IP: 51.250.69.166
==> yandex: Using SSH communicator to connect: 51.250.69.166
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with Ansible...
    yandex: Not using Proxy adapter for Ansible run:
    yandex:     Using ssh keys from Packer communicator...
==> yandex: Executing Ansible: ansible-playbook -e packer_build_name="yandex" -e packer_builder_type=yandex --ssh-extra-args '-o IdentitiesOnly=yes' -e ansible_ssh_private_key_file=/tmp/ansible-key2760680716 -i /tmp/packer-provisioner-ansible186362353 /home/ubuntu/r2d2k_infra/ansible/packer_app.yml
    yandex:
    yandex: PLAY [Install base for application deploy] *************************************
    yandex:
    yandex: TASK [Gathering Facts] *********************************************************
    yandex: ok: [default]
    yandex:
    yandex: TASK [Install packages for app base] *******************************************
    yandex: changed: [default]
    yandex:
    yandex: TASK [Remove useless packages from the cache] **********************************
    yandex: changed: [default]
    yandex:
    yandex: TASK [Remove dependencies that are no longer required] *************************
    yandex: ok: [default]
    yandex:
    yandex: PLAY RECAP *********************************************************************
    yandex: default                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    yandex:
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-app-1658080151
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying subnet...
    yandex: Subnet has been deleted!
==> yandex: Destroying network...
    yandex: Network has been deleted!
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 3 minutes 38 seconds.

==> Wait completed after 3 minutes 38 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-1658080151 (id: fd8r6j5t7u0aqioi5ara) with family name reddit-app
```

Второй образ собираем аналогично.

Заменим в `terraform/stage/terraform.tfvars` идентификаторы дисковых образов на созданные во время выполнения предыдущего шага и запустим формирование инфраструктуры `terraform apply`:
```console
...

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 51.250.95.167
external_ip_address_db = 51.250.95.188
```

Перейдём в папку с `ansible`, проверим, как отрабатывает формирование динамического инвентори `ansible-inventory --list`:
```json
{
    "_meta": {
        "hostvars": {
            "fhm5kep6aqr2gait60hj.auto.internal": {
                "ansible_host": "51.250.95.188"
            },
            "fhmqp579sm5grsc508c8.auto.internal": {
                "ansible_host": "51.250.95.167"
            }
        }
    },
    "all": {
        "children": [
            "app",
            "db",
            "ungrouped"
        ]
    },
    "app": {
        "hosts": [
            "fhmqp579sm5grsc508c8.auto.internal"
        ]
    },
    "db": {
        "hosts": [
            "fhm5kep6aqr2gait60hj.auto.internal"
        ]
    }
}
```

С инвентори всё в порядке, разворачиваем приложение `ansible-playbook site.yml`:
```console

PLAY [Install Python] ****************************************************************************************************

TASK [Install Pyhon use raw module] **************************************************************************************
changed: [fhm5kep6aqr2gait60hj.auto.internal]
changed: [fhmqp579sm5grsc508c8.auto.internal]

PLAY [Configure MongoDB] *************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************
ok: [fhm5kep6aqr2gait60hj.auto.internal]

TASK [Change mongodb config file] ****************************************************************************************
changed: [fhm5kep6aqr2gait60hj.auto.internal]

RUNNING HANDLER [restart mongodb] ****************************************************************************************
changed: [fhm5kep6aqr2gait60hj.auto.internal]

PLAY [Configure App] *****************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************
ok: [fhmqp579sm5grsc508c8.auto.internal]

TASK [Add unit file for Puma] ********************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

TASK [Add config for DB connection] **************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

TASK [enable puma] *******************************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

RUNNING HANDLER [reload puma] ********************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

PLAY [Deploy App] ********************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************
ok: [fhmqp579sm5grsc508c8.auto.internal]

TASK [Install git] *******************************************************************************************************
[WARNING]: Updating cache and auto-installing missing dependency: python-apt
ok: [fhmqp579sm5grsc508c8.auto.internal]

TASK [Fetch the latest version of application code] **************************************************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

TASK [Bundle install] ****************************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

RUNNING HANDLER [reload puma] ********************************************************************************************
changed: [fhmqp579sm5grsc508c8.auto.internal]

PLAY RECAP ***************************************************************************************************************
fhm5kep6aqr2gait60hj.auto.internal : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
fhmqp579sm5grsc508c8.auto.internal : ok=11   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Плэйбук отработал без ошибок, проверяем браузером, доступно ли приложение по адресу http://51.250.95.167:9292.
Ради интереса можем проверить доступ через консольный браузер `lynx`, так не придётся вставлять сюда картинки)
```console
                                                                       Monolith Reddit :: All posts
   (BUTTON) Monolith Reddit
     * Sign up
     * Login

   Can't show blog posts, some problems with database. Refresh?

Menu

     * All posts
     * New post
```

Проблема: приложение запущено, но база данных недоступна. Правильно, мы же всегда задавали руками переменную `db_host` в плэйбуке `app.yml`.
Сделаем так: при выполнении плэйбука настройки сервера баз данных мы создадим хост и сохраним в него переменную, содержащую IP адрес сервера.
При выполнении настроек сервера приложений достанем эту переменную из хоста и подставим в конфигурацию сервиса `puma`.
Это сработает при последовательном выполнении плэйбуков.

Файл `db.yml`:
```yaml
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongodb config file
      template:
        src: templates/mongodb.conf.j2
        dest: /etc/mongodb.conf
        mode: 0644
      notify: restart mongodb

    - name: Store db_host to fake host
      add_host:
        name: "var_holder"
        db_host_ip: "{{ ansible_facts.default_ipv4.address }}"

  handlers:
  - name: restart mongodb
    service: name=mongodb state=restarted
```

Файл `app.yml`:
```yaml
- name: Configure App
  hosts: app
  become: true
  vars:
   db_host: "{{ hostvars['var_holder']['db_host_ip'] }}"
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu
      notify: reload puma

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```

Применяем, проверяем, всё работает.

**Результат №08-3:**
Мы заменили bash скрипты настройки `packer` на плэйбуки `ansible`, создали инфраструктуру и настроили приложение.

Оказалось, что это не конец истории. Проверки при сдаче домашнего задания не проходят, т.к. `packer` в тестовом окружении старый и не в курсе про параметр `use_proxy`. Что ж, будем разбираться.

Текст ошибки: _Failed to connect to the host via ssh: Unable to negotiate with 127.0.0.1 port 46297: no matching host key type found. Their offer: ssh-rsa_.
Судя по всему, все попытки подключения отвергаются, т.к. "удалённый хост" предлагает использовать ключи ssh-rsa, а мы отказываемся. Для подключения `ansible` использует локальную версию `ssh`, у нас установлена _OpenSSH_8.9p1 Ubuntu-3, OpenSSL 3.0.2 15 Mar 2022_. Находим интересную [вещь](https://www.openssh.com/txt/release-8.2). Причина наших проблем: we will be disabling the "ssh-rsa" public key signature algorithm that depends on SHA-1 by default in a near-future release.

Чтобы включить этот алгоритм, мы должны внести изменения в локальный конфиг `ssh`.
```console
> cat ~/.ssh/config
Host *
    HostkeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
```

Убираем из конфигурации `packer` параметр `use_proxy`, проверяем сборку образа, всё проходит успешно.

---

## 09 - Ansible-3

**Задание №09-1:** Ansible: работа с ролями и окружениями
- Переносим созданные плейбуки в раздельные роли
- Описываем два окружения
- Используем коммьюнити роль nginx
- Используем Ansible Vault для наших окружений

**Решение №09-1:**

Создаём папку `roles`, инициализируем два шаблона для ролей:
```console
> ansible-galaxy init app
- Role app was created successfully
> ansible-galaxy init db
- Role db was created successfully

> tree
.
├── app
│   ├── defaults
│   │   └── main.yml
│   ├── handlers
│   │   └── main.yml
│   ├── meta
│   │   └── main.yml
│   ├── README.md
│   ├── tasks
│   │   └── main.yml
│   ├── tests
│   │   ├── inventory
│   │   └── test.yml
│   └── vars
│       └── main.yml
└── db
    ├── defaults
    │   └── main.yml
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── README.md
    ├── tasks
    │   └── main.yml
    ├── tests
    │   ├── inventory
    │   └── test.yml
    └── vars
        └── main.yml

14 directories, 16 files
```

Делим `db.yml` на части, выносим их в соотвествующие файлы `main.yml` роли. Переменные в `default`, обработчики в `handlers`, задачи в `tasks`.
Аналогично разделяем `app.yml`.

В ранее созданных файлах описания приложения и БД заменим задачи и обработчики ролями.

Содержимое файла `app.yml`:
```yaml
- name: Configure App
  hosts: app
  become: true

  vars:
   db_host: 127.0.0.1

  roles:
    - app
```

Содержимое файла `db.yml`:
```yaml
- name: Configure MongoDB
  hosts: db
  become: true

  vars:
    mongo_bind_ip: 0.0.0.0

  roles:
    - db
```

Создаём инфраструктуру для проверки созданных ролей:
```console
> terraform apply
...
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 51.250.68.162
external_ip_address_db = 51.250.1.154
```

В файле `app.yml` обновим переменную, указывающую на адрес сервера баз данных.
Проверим работу ролей:
```console
> ansible-playbook site.yml

PLAY [Install Python] ****************************************************************************************************

TASK [Install Pyhon use raw module] **************************************************************************************
changed: [fhmenfc5uivob0qs79co.auto.internal]
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

PLAY [Configure MongoDB] *************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************
ok: [fhmenfc5uivob0qs79co.auto.internal]

TASK [db : Change mongodb config file] ***********************************************************************************
changed: [fhmenfc5uivob0qs79co.auto.internal]

RUNNING HANDLER [db : restart mongodb] ***********************************************************************************
changed: [fhmenfc5uivob0qs79co.auto.internal]

PLAY [Configure App] *****************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************
ok: [fhma8acfnmsrmemd0s8h.auto.internal]

TASK [app : Add unit file for Puma] **************************************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

TASK [app : Add config for DB connection] ********************************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

TASK [app : enable puma] *************************************************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

RUNNING HANDLER [app : reload puma] **************************************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

PLAY [Deploy App] ********************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************
ok: [fhma8acfnmsrmemd0s8h.auto.internal]

TASK [Install git] *******************************************************************************************************
ok: [fhma8acfnmsrmemd0s8h.auto.internal]

TASK [Fetch the latest version of application code] **********************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

TASK [Bundle install] ****************************************************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

RUNNING HANDLER [reload puma] ********************************************************************************************
changed: [fhma8acfnmsrmemd0s8h.auto.internal]

PLAY RECAP ***************************************************************************************************************
fhma8acfnmsrmemd0s8h.auto.internal : ok=11   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
fhmenfc5uivob0qs79co.auto.internal : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Проверяем работу приложения не выходя из консоли:
```console
> lynx -dump http://51.250.68.162:9292
   (BUTTON) [1]Monolith Reddit
     * [2]Sign up
     * [3]Login

Menu

     * [4]All posts
     * [5]New post
```

Всё на месте :-)

---

Попробуем разделить окружения. Создаём две папки `environtents/prod` и `environtents/stage`, в каждый переносим файл инвентори. Настраиваем окружение по утолчанию, указав путь к инвентори в `ansible.cfg`.
```ini
[defaults]
inventory = ./environments/stage/inventory
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False
```

Зададим переменные для каждого окружения. Для этого создаём в папках окружений каталоги `group_vars`, в них файлы `app` и `db`, содержащие переменные из `app.yml` и `db.yml` соответственно. Также в каждом из окружений создаём файлы `all` с переменной `env` со значением, указывающим на текущее окружение (env: prod и env: stage). В файлы задач каждой роли добавляем вывод значения переменной `env` через модуль `debug`.

При помощи `terraform` создаём окружение `stage`, проверяем работу `ansible-playbook playbooks/site.yml`. Аналогично проверяем работу окружения `prod`, указав путь к файлу инвентори `ansible-playbook -i environments/prod/inventory playbooks/site.yml`.
Видим, что всё работает.

---

Попробуем использовать роли, созданные сообществом. К примеру - при помощи роли `jdauphant.nginx` развернём `nginx` в качестве обратного прокси для нашего приложения. Внешние роли можно указать для каждого окружения в файле зависимостей `requirements.yml`. Создадим такие файлы в каждом из окружений:
```yaml
- src: jdauphant.nginx
  version: v2.21.1
```

Устанавливаем роль:
```console
> ansible-galaxy install -r environments/stage/requirements.yml
Starting galaxy role install process
- downloading role 'nginx', owned by jdauphant
- downloading role from https://github.com/jdauphant/ansible-role-nginx/archive/v2.21.1.tar.gz
- extracting jdauphant.nginx to /.../ansible/roles/jdauphant.nginx
- jdauphant.nginx (v2.21.1) was installed successfully
```

[Документацию](https://github.com/jdauphant/ansible-role-nginx) на роль можно найти на Github.com. Минимально необходимые переменные выглядят так:
```yaml
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / { proxy_pass http://127.0.0.1:9292; }
```

Вносим эти переменные в файлы `app` каждого окружения.

Тут задание внезапно обрывается и нам предлагают самостоятельно доделать остальное:
1. Добавьте в конфигурацию Terraform открытие 80 порта для инстанса приложения
2. Добавьте вызов роли jdauphant.nginx в плейбук app.yml
3. Примените плейбук site.yml для окружения stage и проверьте, что приложение теперь доступно на 80 порту

По пункту 1 - не помню, чтобы мы задавали в Terraform какие-то порты.
По пункту 2 - доавляем внешнюю роль в наш плейбук `app.yml`:
```yaml
- name: Configure App
  hosts: app
  become: true

  roles:
    - app
    - jdauphant.nginx
```

По пункту 3 - пробуем применить `site.yml` и проверим, что приложение доступно на порту 80.

```console
> ansible-playbook playbooks/site.yml

PLAY [Install Python] **************************************************************************************************************************************

TASK [Install Pyhon use raw module] ************************************************************************************************************************
changed: [appserver]
changed: [dbserver]

PLAY [Configure MongoDB] ***********************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************
ok: [dbserver]

TASK [db : Change mongodb config file] *********************************************************************************************************************
ok: [dbserver]

TASK [db : Show info about the env this host belongs to] ***************************************************************************************************
ok: [dbserver] => {
    "msg": "This host is in stage environment!!!"
}

PLAY [Configure App] ***************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************
ok: [appserver]

TASK [app : Add unit file for Puma] ************************************************************************************************************************
ok: [appserver]

TASK [app : Add config for DB connection] ******************************************************************************************************************
--- before: /home/ubuntu/db_config
+++ after: /home/.../tmp/ansible-local-18565nraycpo7/tmpb4wwlyqz/db_config.j2
@@ -1 +1 @@
-DATABASE_URL=0.0.0.0
+DATABASE_URL=51.250.91.16

changed: [appserver]

TASK [app : enable puma] ***********************************************************************************************************************************
ok: [appserver]

TASK [app : Show info about the env this host belongs to] **************************************************************************************************
ok: [appserver] => {
    "msg": "This host is in stage environment!!!"
}

TASK [jdauphant.nginx : include_vars] **********************************************************************************************************************
ok: [appserver] => (item=/home/.../ansible/roles/jdauphant.nginx/vars/../vars/Debian.yml)

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
included: /home/.../ansible/roles/jdauphant.nginx/tasks/installation.packages.yml for appserver

TASK [jdauphant.nginx : Install the epel packages for EL distributions] ************************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : Install the nginx packages from official repo for EL distributions] ****************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : Install the nginx packages for all other distributions] ****************************************************************************
The following additional packages will be installed:
  geoip-database libgd3 libgeoip1 libjbig0 libjpeg-turbo8 libjpeg8 libtiff5
  libvpx3 libxpm4 libxslt1.1 nginx-common nginx-core
Suggested packages:
  libgd-tools geoip-bin fcgiwrap nginx-doc ssl-cert
The following NEW packages will be installed:
  geoip-database libgd3 libgeoip1 libjbig0 libjpeg-turbo8 libjpeg8 libtiff5
  libvpx3 libxpm4 libxslt1.1 nginx nginx-common nginx-core
0 upgraded, 13 newly installed, 0 to remove and 8 not upgraded.
changed: [appserver]

TASK [jdauphant.nginx : Create the directories for site specific configurations] ***************************************************************************
ok: [appserver] => (item=sites-available)
ok: [appserver] => (item=sites-enabled)
--- before
+++ after
@@ -1,4 +1,4 @@
 {
     "path": "/etc/nginx/auth_basic",
-    "state": "absent"
+    "state": "directory"
 }

changed: [appserver] => (item=auth_basic)
ok: [appserver] => (item=conf.d)
--- before
+++ after
@@ -1,4 +1,4 @@
 {
     "path": "/etc/nginx/conf.d/stream",
-    "state": "absent"
+    "state": "directory"
 }

changed: [appserver] => (item=conf.d/stream)
ok: [appserver] => (item=snippets)
--- before
+++ after
@@ -1,4 +1,4 @@
 {
     "path": "/etc/nginx/modules-available",
-    "state": "absent"
+    "state": "directory"
 }

changed: [appserver] => (item=modules-available)
--- before
+++ after
@@ -1,4 +1,4 @@
 {
     "path": "/etc/nginx/modules-enabled",
-    "state": "absent"
+    "state": "directory"
 }

changed: [appserver] => (item=modules-enabled)

TASK [jdauphant.nginx : Ensure log directory exist] ********************************************************************************************************
ok: [appserver]

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
included: /home/.../ansible/roles/jdauphant.nginx/tasks/remove-defaults.yml for appserver

TASK [jdauphant.nginx : Disable the default site] **********************************************************************************************************
--- before
+++ after
@@ -1,4 +1,4 @@
 {
     "path": "/etc/nginx/sites-enabled/default",
-    "state": "link"
+    "state": "absent"
 }

changed: [appserver]

TASK [jdauphant.nginx : Disable the default site (on newer nginx versions)] ********************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : Remove the default configuration] **************************************************************************************************
ok: [appserver]

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : Remove unwanted sites] *************************************************************************************************************

TASK [jdauphant.nginx : Remove unwanted conf] **************************************************************************************************************

TASK [jdauphant.nginx : Remove unwanted snippets] **********************************************************************************************************

TASK [jdauphant.nginx : Remove unwanted auth_basic_files] **************************************************************************************************

TASK [jdauphant.nginx : Copy the nginx configuration file] *************************************************************************************************
--- before: /etc/nginx/nginx.conf
+++ after: /home/.../tmp/ansible-local-18565nraycpo7/tmprkvn5pgn/nginx.conf.j2
@@ -1,85 +1,33 @@
-user www-data;
-worker_processes auto;
-pid /run/nginx.pid;
+#Ansible managed
+user              www-data  www-data;
+
+worker_processes  2;
+
+pid        /var/run/nginx.pid;
+
+worker_rlimit_nofile 1024;
+
+include /etc/nginx/modules-enabled/*.conf;
+

 events {
-       worker_connections 768;
-       # multi_accept on;
+        worker_connections 512;
 }
+

 http {

-       ##
-       # Basic Settings
-       ##
+        include /etc/nginx/mime.types;
+        default_type application/octet-stream;
+        sendfile on;
+        tcp_nopush on;
+        tcp_nodelay on;
+        server_tokens off;
+        access_log "/var/log/nginx/access.log";
+        error_log "/var/log/nginx/error.log" error;

-       sendfile on;
-       tcp_nopush on;
-       tcp_nodelay on;
-       keepalive_timeout 65;
-       types_hash_max_size 2048;
-       # server_tokens off;
-
-       # server_names_hash_bucket_size 64;
-       # server_name_in_redirect off;
-
-       include /etc/nginx/mime.types;
-       default_type application/octet-stream;
-
-       ##
-       # SSL Settings
-       ##
-
-       ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
-       ssl_prefer_server_ciphers on;
-
-       ##
-       # Logging Settings
-       ##
-
-       access_log /var/log/nginx/access.log;
-       error_log /var/log/nginx/error.log;
-
-       ##
-       # Gzip Settings
-       ##
-
-       gzip on;
-       gzip_disable "msie6";
-
-       # gzip_vary on;
-       # gzip_proxied any;
-       # gzip_comp_level 6;
-       # gzip_buffers 16 8k;
-       # gzip_http_version 1.1;
-       # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
-
-       ##
-       # Virtual Host Configs
-       ##
-
-       include /etc/nginx/conf.d/*.conf;
-       include /etc/nginx/sites-enabled/*;
+        include /etc/nginx/conf.d/*.conf;
+        include /etc/nginx/sites-enabled/*;
 }


-#mail {
-#      # See sample authentication script at:
-#      # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
-#
-#      # auth_http localhost/auth.php;
-#      # pop3_capabilities "TOP" "USER";
-#      # imap_capabilities "IMAP4rev1" "UIDPLUS";
-#
-#      server {
-#              listen     localhost:110;
-#              protocol   pop3;
-#              proxy      on;
-#      }
-#
-#      server {
-#              listen     localhost:143;
-#              protocol   imap;
-#              proxy      on;
-#      }
-#}

changed: [appserver]

TASK [jdauphant.nginx : Ensure auth_basic files created] ***************************************************************************************************

TASK [jdauphant.nginx : Create the configurations for sites] ***********************************************************************************************
--- before
+++ after: /home/.../tmp/ansible-local-18565nraycpo7/tmpjdxtm4uo/site.conf.j2
@@ -0,0 +1,10 @@
+#Ansible managed
+
+server {
+   listen 80;
+   server_name "reddit";
+   location / {
+       proxy_pass http://127.0.0.1:9292;
+
+   }
+}

changed: [appserver] => (item={'key': 'default', 'value': ['listen 80', 'server_name "reddit"', 'location / { proxy_pass http://127.0.0.1:9292; }']})

TASK [jdauphant.nginx : Create links for sites-enabled] ****************************************************************************************************
--- before
+++ after
@@ -1,4 +1,4 @@
 {
     "path": "/etc/nginx/sites-enabled/default.conf",
-    "state": "absent"
+    "state": "link"
 }

changed: [appserver] => (item={'key': 'default', 'value': ['listen 80', 'server_name "reddit"', 'location / { proxy_pass http://127.0.0.1:9292; }']})

TASK [jdauphant.nginx : Create the configurations for independent config file] *****************************************************************************

TASK [jdauphant.nginx : Create configuration snippets] *****************************************************************************************************

TASK [jdauphant.nginx : Create the configurations for independent config file for streams] *****************************************************************

TASK [jdauphant.nginx : Create links for modules-enabled] **************************************************************************************************

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : include_tasks] *********************************************************************************************************************
skipping: [appserver]

TASK [jdauphant.nginx : Start the nginx service] ***********************************************************************************************************
changed: [appserver]

RUNNING HANDLER [app : reload puma] ************************************************************************************************************************
changed: [appserver]

RUNNING HANDLER [jdauphant.nginx : restart nginx] **********************************************************************************************************
changed: [appserver] => {
    "msg": "checking config first"
}

RUNNING HANDLER [jdauphant.nginx : reload nginx] ***********************************************************************************************************
changed: [appserver] => {
    "msg": "checking config first"
}

RUNNING HANDLER [jdauphant.nginx : check nginx configuration] **********************************************************************************************
ok: [appserver]

RUNNING HANDLER [jdauphant.nginx : restart nginx - after config check] *************************************************************************************
changed: [appserver]

RUNNING HANDLER [jdauphant.nginx : reload nginx - after config check] **************************************************************************************
changed: [appserver]

PLAY [Deploy App] ******************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************
ok: [appserver]

TASK [Install git] *****************************************************************************************************************************************
ok: [appserver]

TASK [Fetch the latest version of application code] ********************************************************************************************************
ok: [appserver]

TASK [Bundle install] **************************************************************************************************************************************
ok: [appserver]

PLAY RECAP *************************************************************************************************************************************************
appserver                  : ok=28   changed=14   unreachable=0    failed=0    skipped=17   rescued=0    ignored=0
dbserver                   : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Проверяем приложение на порту 80:
```console
> lynx -dump http://51.250.94.249:80
   (BUTTON) [1]Monolith Reddit
     * [2]Sign up
     * [3]Login

Menu

     * [4]All posts
     * [5]New post

References
```

Всё работает.

---

Проверим, как работает ansible vault. Создадим файл `vault.key` с ключом шифрования и добавим файл в `.gitignore`. Также его можно указать в `ansible.cfg`:
```ini
[defaults]
...
vault_password_file = vault.key
```

Создаём плейбук для добавления пользователей `ansible/playbooks/users.yml`:
```yaml
- name: Create users
  hosts: all
  become: true

  vars_files:
    - "{{ inventory_dir }}/credentials.yml"

  tasks:
    - name: create users
      user:
        name: "{{ item.key }}"
        password: "{{ item.value.password|password_hash('sha512', 65534|random(seed=inventory_hostname)|string) }}"
        groups: "{{ item.value.groups | default(omit) }}"
      with_dict: "{{ credentials.users }}"
```

Создаём файлы с параметрами пользователей, свои для каждого окружения.

Файл `ansible/environments/prod/credentials.yml`:

```yaml
credentials:
  users:
    admin:
      password: admin123
      groups: sudo
```

Файл `ansible/environments/stage/credentials.yml`:

```yaml
credentials:
  users:
    admin:
      password: qwerty123
      groups: sudo
    qauser:
      password: test123
```

Шифруем содержимое командой `ansible-vault encrypt environments/.../credentials.yml`. Проверяем:
```console
> cat environments/prod/credentials.yml
$ANSIBLE_VAULT;1.1;AES256
35303863666462356132656331393038623562363333616334316561376433623966636238383831
6333663863393839626131373336633064396363393831320a636263366439343338393461656461
39356133333133383561366165646437653631653330393037303339333338326663666334356130
6231323338316263330a393564363865393862363565313831396464633334353034386564373939
36396466346435656436356234363032336565313337393930313233663936613630653938343733
62653061613031366161346639396661623638316131626336313062356265353639356236616266
38393263343838663965316330393635313034373737393939663337386264653764306362333334
30633333303837303334
```

Файл зашифрован, чего мы и добивались. Добавляем задачу создания пользователей в `site.yml`:
```yaml
- import_playbook: install_python.yml
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
- import_playbook: users.yml
```
Применяем, проверяем, что пользователи созданы:
```console
> ssh -l admin 51.250.94.249
admin@51.250.94.249's password:
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

$ id
uid=1001(admin) gid=1002(admin) groups=1002(admin),27(sudo)
$
Connection to 51.250.94.249 closed.

> ssh -l qauser 51.250.94.249
qauser@51.250.94.249's password:
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

$ id
uid=1002(qauser) gid=1003(qauser) groups=1003(qauser)
$
Connection to 51.250.94.249 closed.
```

Всё работает.

**Результат №09-1:**
Мы научились создавать, использовать роли, поработали с ролями, созданными сообществом Ansible. Разделили окружение на prod и stage, зашифровали чувствительные данные.

---

**Задание №09-2:**
В прошлом ДЗ было задание со ⭐ про работу с динамическим инвентори. Настройте использование динамического инвентори для окружений stage и prod.
В коде Ansible это должно быть закоммичено.

**Решение №09-2:**
Переносим в каталоги `prod` и `stage` наш файл из предыдущего задания с динамическим инвентори `yc.yml`. Добавляем файл с ключом `ansible-key.json` в корень папки с конфигом `ansible`, прописываем использование плагина в `ansible.cfg`.
```ini
[defaults]
inventory = ./environments/stage/yc.yml
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False
roles_path = ./roles
vault_password_file = vault.key

[diff]
always = True
context = 5

[inventory]
enable_plugins = yc_compute
```

Создаём инфраструктуру при помощи `terraform apply` и проверяем работу инвентори:
```console
> ansible-inventory --list
{
    "_meta": {
        "hostvars": {
            "fhme5fs09pcb9tcnu1hi.auto.internal": {
                "ansible_host": "51.250.85.175",
                "db_host": "51.250.91.16",
                "env": "stage",
                "nginx_sites": {
                    "default": [
                        "listen 80",
                        "server_name \"reddit\"",
                        "location / { proxy_pass http://127.0.0.1:9292; }"
                    ]
                }
            },
            "fhmhkqmoe5cpuai7taba.auto.internal": {
                "ansible_host": "51.250.81.57",
                "env": "stage",
                "mongo_bind_ip": "0.0.0.0"
            }
        }
    },
    "all": {
        "children": [
            "app",
            "db",
            "ungrouped"
        ]
    },
    "app": {
        "hosts": [
            "fhme5fs09pcb9tcnu1hi.auto.internal"
        ]
    },
    "db": {
        "hosts": [
            "fhmhkqmoe5cpuai7taba.auto.internal"
        ]
    }
}
```

**Результат №09-2:**

Применяем плейбуки, всё работает, но уже с динамическим инвентори.

---

## 10 - Ansible-4

**Задание №10-1:** Разработка и тестирование Ansible ролей и плейбуков
- Локальная разработка при помощи Vagrant, доработка ролей для провижининга в Vagrant
- Тестирование ролей при помощи Molecule и Testinfra
- Переключение сбора образов пакером на использование ролей

**Решение №10-1:**

Начнём. Используется Ubuntu, поэтому установка `vagrant` будет выглядеть так:
```console
> sudo apt install vagrant virtualbox
...


> vagrant -v
Vagrant 2.2.19
```

Для того, чтобы не тащить ненужное в репозиторий, обновим `.gitignore`:
```console
> cat .gitignore
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
*.tfbackend
.terraform/
terraform-key.json
packer-key.json
ansible-key.json
.terraform.lock.hcl
*.retry
jdauphant.nginx
vault.key

# Vagrant & molecule
.vagrant/
*.log
*.pyc
.molecule
.cache
.pytest_cache
```

В папке ansible создаём `Vagrantfile` для подготовки нашей инфраструктуры:
```ruby
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "192.168.56.10"
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "192.168.56.20"
  end
end
```

Запускаем наше окружение при помощи `vagrant up`:
```console
> vagrant up
Bringing machine 'dbserver' up with 'virtualbox' provider...
Bringing machine 'appserver' up with 'virtualbox' provider...
==> dbserver: Importing base box 'ubuntu/xenial64'...
==> dbserver: Matching MAC address for NAT networking...
==> dbserver: Checking if box 'ubuntu/xenial64' version '20211001.0.0' is up to date...
==> dbserver: Setting the name of the VM: ansible_dbserver_1659585564464_33750
==> dbserver: Clearing any previously set network interfaces...
==> dbserver: Preparing network interfaces based on configuration...
    dbserver: Adapter 1: nat
    dbserver: Adapter 2: hostonly
==> dbserver: Forwarding ports...
    dbserver: 22 (guest) => 2222 (host) (adapter 1)
==> dbserver: Running 'pre-boot' VM customizations...
==> dbserver: Booting VM...
==> dbserver: Waiting for machine to boot. This may take a few minutes...
    dbserver: SSH address: 127.0.0.1:2222
    dbserver: SSH username: vagrant
    dbserver: SSH auth method: private key
    dbserver: Warning: Connection reset. Retrying...
    dbserver:
    dbserver: Vagrant insecure key detected. Vagrant will automatically replace
    dbserver: this with a newly generated keypair for better security.
    dbserver:
    dbserver: Inserting generated public key within guest...
    dbserver: Removing insecure key from the guest if it's present...
    dbserver: Key inserted! Disconnecting and reconnecting using new SSH key...
==> dbserver: Machine booted and ready!
==> dbserver: Checking for guest additions in VM...
==> dbserver: Setting hostname...
==> dbserver: Configuring and enabling network interfaces...
==> dbserver: Mounting shared folders...
    dbserver: /vagrant => /home/.../ansible
==> appserver: Importing base box 'ubuntu/xenial64'...
==> appserver: Matching MAC address for NAT networking...
==> appserver: Checking if box 'ubuntu/xenial64' version '20211001.0.0' is up to date...
==> appserver: Setting the name of the VM: ansible_appserver_1659585668688_5229
==> appserver: Fixed port collision for 22 => 2222. Now on port 2200.
==> appserver: Clearing any previously set network interfaces...
==> appserver: Preparing network interfaces based on configuration...
    appserver: Adapter 1: nat
    appserver: Adapter 2: hostonly
==> appserver: Forwarding ports...
    appserver: 22 (guest) => 2200 (host) (adapter 1)
==> appserver: Running 'pre-boot' VM customizations...
==> appserver: Booting VM...
==> appserver: Waiting for machine to boot. This may take a few minutes...
    appserver: SSH address: 127.0.0.1:2200
    appserver: SSH username: vagrant
    appserver: SSH auth method: private key
    appserver:
    appserver: Vagrant insecure key detected. Vagrant will automatically replace
    appserver: this with a newly generated keypair for better security.
    appserver:
    appserver: Inserting generated public key within guest...
    appserver: Removing insecure key from the guest if it's present...
    appserver: Key inserted! Disconnecting and reconnecting using new SSH key...
==> appserver: Machine booted and ready!
==> appserver: Checking for guest additions in VM...
==> appserver: Setting hostname...
==> appserver: Configuring and enabling network interfaces...
==> appserver: Mounting shared folders...
    appserver: /vagrant => /home/.../ansible
```

Внешне всё хорошо и без ошибок. Проверим, как себя чувствуют виртуальные машины:
```console
> vagrant status
Current machine states:

dbserver                  running (virtualbox)
appserver                 running (virtualbox)
```

Проверим возможность входа в консоль машин:
```console
> vagrant ssh dbserver
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-210-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

UA Infra: Extended Security Maintenance (ESM) is not enabled.

0 updates can be applied immediately.

45 additional security updates can be applied with UA Infra: ESM
Learn more about enabling UA Infra: ESM service for Ubuntu 16.04 at
https://ubuntu.com/16-04

New release '18.04.6 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


vagrant@dbserver:~$ logout
```

Проверим сетевую связность:
```console
> ping 192.168.56.10
PING 192.168.56.10 (192.168.56.10) 56(84) bytes of data.
64 bytes from 192.168.56.10: icmp_seq=1 ttl=64 time=1.45 ms
64 bytes from 192.168.56.10: icmp_seq=2 ttl=64 time=0.613 ms
64 bytes from 192.168.56.10: icmp_seq=3 ttl=64 time=0.518 ms
64 bytes from 192.168.56.10: icmp_seq=4 ttl=64 time=0.673 ms
...
```

Vagrant поддерживает большое количество провижинеров, которые позволяют автоматизировать процесс конфигурации созданных VMs с использованием популярных инструментов управления конфигурацией и обычных скриптов на bash. Мы будем использовать Ansible провижинер для проверки работы наших ролей и плейбуков.

Добавим в описание хоста `dbserver` секцию для `ansible`:
```ruby
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "192.168.56.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "192.168.56.20"
  end
end
```

Применим настройку к хосту `dbserver`:
```console
> vagrant provision dbserver
==> dbserver: Running provisioner: ansible...
    dbserver: Running ansible-playbook...
[WARNING]: Failed to load inventory plugin, skipping yc_compute
ERROR! No inventory plugins available to generate inventory, make sure you have at least one whitelisted.
Ansible failed to complete successfully. Any error output should be
visible above. Please fix these errors and try again.
```

У нас остались старые хвосты от предыдущих занятий, поэтому закомментируем плагин в файле `ansible.cfg`. Данная работа выполняется на свежей машине, куда перенесён только репозиторий с заданиями. Плагины, которые мы ставили руками, сюда не переехали. После удаления ссылок на `yc_compute` проверяем работу ещё раз:
```console
> vagrant provision dbserver
==> dbserver: Running provisioner: ansible...
    dbserver: Running ansible-playbook...

PLAY [Install Python] **********************************************************

TASK [Gathering Facts] *********************************************************
ok: [dbserver]

TASK [Check for Python] ********************************************************
ok: [dbserver]

TASK [Install Pyhon use raw module] ********************************************
changed: [dbserver]

PLAY [Configure MongoDB] *******************************************************

TASK [Gathering Facts] *********************************************************
ok: [dbserver]

TASK [db : Change mongodb config file] *****************************************
--- before
+++ after: /home/.../.ansible/tmp/ansible-local-168462871rmro/tmp7lyb8x79/mongodb.conf.j2
@@ -0,0 +1,16 @@
+# Where and how to store data.
+storage:
+  dbPath: /var/lib/mongodb
+  journal:
+    enabled: true
+
+# where to write logging data.
+systemLog:
+  destination: file
+  logAppend: true
+  path: /var/log/mongodb/mongod.log
+
+# network interfaces
+net:
+  port: 27017
+  bindIp: 0.0.0.0

changed: [dbserver]

TASK [db : Show info about the env this host belongs to] ***********************
ok: [dbserver] => {
    "msg": "This host is in local environment!!!"
}

RUNNING HANDLER [db : restart mongodb] *****************************************
fatal: [dbserver]: FAILED! => {"changed": false, "msg": "Could not find the requested service mongodb: host"}

NO MORE HOSTS LEFT *************************************************************

PLAY RECAP *********************************************************************
dbserver                   : ok=6    changed=2    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0

Ansible failed to complete successfully. Any error output should be
visible above. Please fix these errors and try again.
```

В стандартном домашнем задании всё должно упасть, потому, что не сможет найти `python`. У меня же `python` устанавливался при помощи модуля `raw`:
```yaml
- name: Install Python
  hosts: all
  gather_facts: true

  tasks:
    - name: Check for Python
      raw: test -e /usr/bin/python
      changed_when: false
      failed_when: false
      register: check_python_result

    - name: Install Pyhon use raw module
      raw: apt install -y python
      become: true
      when: check_python_result.rc != 0
```

Домашнее задание ожидает, что установка `python` будет выпоняться плейбуком `base.yml`, так что я переименую свой и обновлю `site.yml`:
```yaml
- import_playbook: base.yml
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```

Выше было видно, что `ansible` выдавал ошибку, когда не мог перезапустить `mongodb`. Логично, т.к. ранее мы разворачивали инфраструктуру из подготовленных образов, в которых `mongodb` была предустановлена. Не проблема, используем плейбук `packer_db.yml`, созданный в предыдущих заданиях. Каждое задание пометим тегом `install`. В итоге получим файл `install_mongo.yml`:
```yaml
- name: Install mongodb
  apt:
    name: mongodb
    state: present
    update_cache: yes
  retries: 5
  delay: 20
  tags: install

- name: Remove useless packages from the cache
  apt:
    autoclean: yes
  tags: install

- name: Remove dependencies that are no longer required
  apt:
    autoremove: yes
  tags: install

- name: Enable mongodb service
  systemd:
    name: mongodb
    enabled: yes
  tags: install
```

Настройку `mongodb` вынесем в отдельный файл `config_mongo.yml`:
```yaml
- name: Change mongodb config file
  template:
    src: mongodb.conf.j2
    dest: /etc/mongodb.conf
    mode: 0644
  notify: restart mongodb
```

Вызов задач будем производить из `main.yml`:
```yaml
# tasks file for db

- name: Show info about the env this host belongs to
  debug: msg="This host is in {{ env }} environment!!!"

- include: install_mongo.yml
- include: config_mongo.yml
```

Проверим, как работают наши изменения, применив их при помощи `vagrant provision dbserver`:
```console
==> dbserver: Running provisioner: ansible...
    dbserver: Running ansible-playbook...

PLAY [Install Python] **********************************************************

TASK [Gathering Facts] *********************************************************
ok: [dbserver]

TASK [Check for Python] ********************************************************
ok: [dbserver]

TASK [Install Pyhon use raw module] ********************************************
skipping: [dbserver]

PLAY [Configure MongoDB] *******************************************************

TASK [Gathering Facts] *********************************************************
ok: [dbserver]

TASK [db : Show info about the env this host belongs to] ***********************
ok: [dbserver] => {
    "msg": "This host is in local environment!!!"
}

TASK [db : Install mongodb] ****************************************************
The following additional packages will be installed:
  libboost-filesystem1.58.0 libboost-program-options1.58.0
  libboost-system1.58.0 libboost-thread1.58.0 libgoogle-perftools4
  libpcrecpp0v5 libsnappy1v5 libtcmalloc-minimal4 libunwind8 libv8-3.14.5
  libyaml-cpp0.5v5 mongodb-clients mongodb-server
The following NEW packages will be installed:
  libboost-filesystem1.58.0 libboost-program-options1.58.0
  libboost-system1.58.0 libboost-thread1.58.0 libgoogle-perftools4
  libpcrecpp0v5 libsnappy1v5 libtcmalloc-minimal4 libunwind8 libv8-3.14.5
  libyaml-cpp0.5v5 mongodb mongodb-clients mongodb-server
0 upgraded, 14 newly installed, 0 to remove and 1 not upgraded.
[WARNING]: Updating cache and auto-installing missing dependency: python-apt
changed: [dbserver]

TASK [db : Remove useless packages from the cache] *****************************
ok: [dbserver]

TASK [db : Remove dependencies that are no longer required] ********************
ok: [dbserver]

TASK [db : Enable mongodb service] *********************************************
ok: [dbserver]

TASK [db : Change mongodb config file] *****************************************
ok: [dbserver]
[WARNING]: Could not match supplied host pattern, ignoring: app

PLAY [Configure App] ***********************************************************
skipping: no hosts matched

PLAY [Deploy App] **************************************************************
skipping: no hosts matched

PLAY RECAP *********************************************************************
dbserver                   : ok=9    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

Зайдём на `dbserver` и проверим статус `mongodb`:
```condole
vagrant@dbserver:~$ systemctl status mongodb
● mongodb.service - An object/document-oriented database
   Loaded: loaded (/lib/systemd/system/mongodb.service; enabled; vendor preset: e
   Active: active (running) since Thu 2022-08-04 04:51:08 UTC; 46s ago
     Docs: man:mongod(1)
 Main PID: 1166 (mongod)
    Tasks: 10
   Memory: 60.2M
      CPU: 848ms
   CGroup: /system.slice/mongodb.service
           └─1166 /usr/bin/mongod --config /etc/mongodb.conf
```

Аналогичным способом обновим роль `app`, перенесём в неё задачи установки и настройки нашего приложения `reddit-app`.
Файл `ruby.yml`:
```yaml
- name: Install packages for app base
  apt:
    name: ['apt-transport-https', 'ca-certificates', 'ruby-full', 'ruby-bundler', 'build-essential', 'git']
    state: present
    update_cache: yes
  retries: 5
  delay: 20
  tags: ruby

- name: Remove useless packages from the cache
  apt:
    autoclean: yes
  tags: ruby

- name: Remove dependencies that are no longer required
  apt:
    autoremove: yes
  tags: ruby
```

Файл `puma.yml`:
```yaml
- name: Add unit file for Puma
  copy:
    src: puma.service
    dest: /etc/systemd/system/puma.service
    mode: '0644'
  notify: reload puma
  tags: puma

- name: Add config for DB connection
  template:
    src: db_config.j2
    dest: /home/ubuntu/db_config
    owner: ubuntu
    group: ubuntu
    mode: '0644'
  notify: reload puma
  tags: puma

- name: enable puma
  systemd: name=puma enabled=yes
  tags: puma
```

Ну и сам файл `main.yml`:
```yaml
# tasks file for app

- name: Show info about the env this host belongs to
  debug:
    msg: "This host is in {{ env }} environment!!!"

- include: ruby.yml
- include: puma.yml
```

`Vagrantfile` также нужно обновить, добавив туда секцию настройки `appserver`:
```ruby
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "192.168.56.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "192.168.56.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => {"db_host" => "192.168.56.10"}
      }
    end
  end
end
```

Проверяем наши изменения, запустив `vagrant provision appserver`. Процесс отработал, ошибок нет. В методичке сказано, что долны быть проблемы из-за некорректного пользователя. У нас пользователь совпал, проблем нет. Предлагается параметризировать конфигурацию, чтобы можно было использовать любого пользователя. Сделаем это.

Добавляем пользователя в `roles/app/defaults/main.yml`:
```yaml
# defaults file for app

db_host: 127.0.0.1
env: local
deploy_user: appuser
```

Затем меняем `roles/app/tasks/puma.yaml`, unit-файл будем добавлять через шаблон:
```yaml
- name: Add unit file for Puma
  template:
    src: puma.service.j2
    dest: /etc/systemd/system/puma.service
    mode: '0644'
  notify: reload puma
  tags: puma

- name: Add config for DB connection
  template:
    src: db_config.j2
    dest: /home/ubuntu/db_config
    owner: ubuntu
    group: ubuntu
    mode: '0644'
  notify: reload puma
  tags: puma

- name: enable puma
  systemd: name=puma enabled=yes
  tags: puma
```

Переместим `roles/app/files/puma.service` в `roles/app/templates/puma.service.j2` и заменим все упоминания пользователя на переменную:
```ini
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/{{ deploy_user }}/db_config
User={{ deploy_user }}
WorkingDirectory=/home/{{ deploy_user }}/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

Также вносим параметры в `roles/app/tasks/puma.yml`:
```yaml
- name: Add unit file for Puma
  template:
    src: puma.service.j2
    dest: /etc/systemd/system/puma.service
    mode: '0644'
  notify: reload puma
  tags: puma

- name: Add config for DB connection
  template:
    src: db_config.j2
    dest: "/home/{{ deploy_user }}/db_config"
    owner: "{{ deploy_user }}"
    group: "{{ deploy_user }}"
    mode: '0644'
  notify: reload puma
  tags: puma

- name: enable puma
  systemd: name=puma enabled=yes
  tags: puma
```

Не забываем про `playbooks/deploy.yml`:
```yaml
- name: Deploy App
  hosts: app
  become: true
  tasks:
    - name: Install git
      apt:
        name: git
        state: present

    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: "/home/{{ deploy_user }}/reddit"
        version: monolith
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: "/home/{{ deploy_user }}/reddit"
      notify: reload puma

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted
```

Переменную задаим в `Vagtantfile`:
```ruby
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "192.168.56.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "192.168.56.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => {"db_host" => "192.168.56.10"}
      }
      ansible.extra_vars = {
      "deploy_user" => "ubuntu"
      }
    end
  end
end
```

Запускаем `vagrant provision appserver` и проверяем работу приложения `lynx http://192.168.56.20:9292`:

```console
                                                     Monolith Reddit :: All posts
   (BUTTON) Monolith Reddit
     * Sign up
     * Login

Menu

     * All posts
     * New post
```

Для уверенности, что всё работает корректно, можно удалить машины `vagrant destroy` и создать их заново `vagrant up`. После запуска и настройки машин проверяем доступность приложения на порту 9292. Всё работает корректно :)

---

Если подключиться к порту 80 сервера приложений, то мы увидим стартовую страницу `nginx`, а не то, что мы хотели. Надо разобраться.
Для настройки `nginx` мы используем роль, которая ожидает настройки в виде списка сайтов в переменной `nginx_sites`. В исходных переменных список состоял только из одного сайта и выглядел так:
```yaml
  default:
    - listen 80
    - server_name reddit
    - location / { proxy_pass http://127.0.0.1:9292; }
```

Берём любой [конвертер YAML2JSON](https://www.json2yaml.com/convert-yaml-to-json) и получаем на выходе это:
```json
{
  "default": [
    "listen 80",
    "server_name reddit",
    "location / { proxy_pass http://127.0.0.1:9292; }"
  ]
}
```

Добавляем этот JSON в переменную `nginx_sites` и получаем наш `Vagrantfile`:
```ruby
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "192.168.56.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "192.168.56.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
        "app" => ["appserver"],
        "app:vars" => {
          "db_host" => "192.168.56.10",
          "nginx_sites" => '{"default":["listen 80", "server_name reddit", "location / { proxy_pass http://127.0.0.1:9292; }"]}'
        }
      }
      ansible.extra_vars = { "deploy_user" => "ubuntu" }
    end
  end
end
```

Применяем настройки к серверу `vagrant provision appserver`, проверяем, сервер приложений отвечает нашим сайтом на порту 80.

---

Переходим к тестированию ролей. Для локального тестирования будем использовать Molecule для создания машин и проверки конфигурации и Testinfra для написания тестов. Настроим окружение, установим все необходимые инструменты. Обновляем файл зависимостей:
```console
> cat requirements.txt
ansible>=2.4
molecule>=2.6
testinfra>=1.10
python-vagrant>=0.5.15
molecule-vagrant>=1.0.0
```

Устанавливаем инструменты: `pip install -r requirements.txt`. Проверяем, что всё работает:
```console
> ansible --version
ansible 2.10.8

> molecule --version
molecule 4.0.1 using python 3.10
    ansible:2.10.8
    delegated:4.0.1 from molecule
    vagrant:1.0.0 from molecule_vagrant

> py.test-3
============================== test session starts ==============================
platform linux -- Python 3.10.4, pytest-6.2.5, py-1.10.0, pluggy-0.13.0 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /home/.../ansible
plugins: testinfra-6.5.0
collected 0 items
============================= no tests ran in 0.02s =============================
```

Тестирование начнём с роли `db`. В папке с ролью инициализируем сценарий:
```console
> molecule init scenario -r db -d vagrant
INFO     Initializing new scenario default...
INFO     Initialized scenario in /home/.../ansible/roles/db/molecule/default successfully.
```

В файле описания виртуальной машины `ansible/roles/db/molecule/default/molecule.yml`, поле `box`, укажем исходный образ. Так, как для проверки ролей мы планируем использовать фреймворк `testinfra`, то укажем его в секции `verifier`:
```yaml
dependency:
  name: galaxy
driver:
  name: vagrant
platforms:
  - name: instance
    box: ubuntu/xenial64
provisioner:
  name: ansible
verifier:
  name: testinfra
```

Далее создаём машину для проверки роли. Для этого в папке `ansible/roles/db` выполняем `molecule create`:
```console
INFO     default scenario test matrix: dependency, create, prepare
INFO     Performing prerun with role_name_check=0...
INFO     Running default > dependency
INFO     Running default > create

PLAY [Create] *****************************************************************************************************

TASK [Create molecule instance(s)] ********************************************************************************
changed: [localhost]

TASK [Populate instance config dict] ******************************************************************************
ok: [localhost] => (item={'Host': 'instance', 'HostName': '127.0.0.1', 'User': 'vagrant', 'Port': '2222',
'UserKnownHostsFile': '/dev/null', 'StrictHostKeyChecking': 'no', 'PasswordAuthentication': 'no',
'IdentityFile': '/home/.../.cache/molecule/db/default/.vagrant/machines/instance/virtualbox/private_key',
'IdentitiesOnly': 'yes', 'LogLevel': 'FATAL'})

TASK [Convert instance config dict to a list] *********************************************************************
ok: [localhost]

TASK [Dump instance config] ***************************************************************************************
changed: [localhost]

PLAY RECAP *******************************************************************************************************
localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Running default > prepare

PLAY [Prepare] ****************************************************************************************************

TASK [Bootstrap python for Ansible] *******************************************************************************
ok: [instance]

PLAY RECAP ********************************************************************************************************
instance                   : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

Проверим, что машина была создана и доступна для работы:
```console
> molecule list
INFO     Running default > list
               ╷             ╷             ╷              ╷         ╷
  Instance     │             │ Provisioner │ Scenario     │         │
  Name         │ Driver Name │ Name        │ Name         │ Created │ Converged
╶──────────────┼─────────────┼─────────────┼──────────────┼─────────┼───────────╴
  instance     │ vagrant     │ ansible     │ default      │ true    │ false
               ╵             ╵             ╵              ╵         ╵
```

В файл `ansible/roles/db/molecule/defaultconverge.yml` добавим `become` и переменную `mongo_bind_ip`:
```yaml
- name: Converge
  hosts: all
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: "Include db"
      include_role:
        name: "db"
```

Применим роль к созданной виртуальной машине:
```console
> molecule converge

INFO     default scenario test matrix: dependency, create, prepare, converge
INFO     Performing prerun with role_name_check=0...
INFO     Running default > dependency
INFO     Running default > create
INFO     Running default > prepare
INFO     Running default > converge

PLAY [Converge] **************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [instance]

TASK [Include db] ************************************************************************************************

TASK [db : Show info about the env this host belongs to] *********************************************************
ok: [instance] => {
    "msg": "This host is in local environment!!!"
}

TASK [db : Install mongodb] **************************************************************************************
changed: [instance]

TASK [db : Remove useless packages from the cache] ***************************************************************
ok: [instance]

TASK [db : Remove dependencies that are no longer required] ******************************************************
ok: [instance]

TASK [db : Enable mongodb service] *******************************************************************************
ok: [instance]

TASK [db : Change mongodb config file] ***************************************************************************
changed: [instance]

RUNNING HANDLER [db : restart mongodb] ***************************************************************************
changed: [instance]

PLAY RECAP *******************************************************************************************************
instance                   : ok=8    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

При желании можно зайти на созданную машину `molecule login -h instance` проверить состояние сервиса `mongodb`:
```console
vagrant@instance:~$ systemctl status mongodb
● mongodb.service - An object/document-oriented database
   Loaded: loaded (/lib/systemd/system/mongodb.service; enabled; vendor preset: e
   Active: active (running) since Wed 1986-04-25 21:23:00 UTC; 36 years ago
     Docs: man:mongod(1)
 Main PID: 777 (mongod)
    Tasks: 10
   Memory: 45.3M
      CPU: 1.226s
   CGroup: /system.slice/mongodb.service
           └─777 /usr/bin/mongod --config /etc/mongodb.conf
```

Статус машины изменился:
```console
> molecule list
INFO     Running default > list
               ╷             ╷             ╷              ╷         ╷
  Instance     │             │ Provisioner │ Scenario     │         │
  Name         │ Driver Name │ Name        │ Name         │ Created │ Converged
╶──────────────┼─────────────┼─────────────┼──────────────┼─────────┼───────────╴
  instance     │ vagrant     │ ansible     │ default      │ true    │ true
               ╵             ╵             ╵              ╵         ╵
```

Для проверки создадим простые тесты в файле `ansible/roles/db/molecule/default/tests/test_default.py`:
```python
import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')

# check if MongoDB is enabled and running
def test_mongo_running_and_enabled(host):
    mongo = host.service("mongodb")
    assert mongo.is_running
    assert mongo.is_enabled

# check if configuration file contains the required line
def test_config_file(host):
    config_file = host.file('/etc/mongodb.conf')
    assert config_file.contains('bindIp: 0.0.0.0')
    assert config_file.is_file
```

Запускаем тест:
```console
> molecule verify
INFO     default scenario test matrix: verify
INFO     Performing prerun with role_name_check=0...
INFO     Running default > verify
INFO     Executing Testinfra tests found in /home/.../ansible/roles/db/molecule/default/tests/...
Unknown command: pytest

pytest --ansible-inventory /home/.../.cache/molecule/db/default/inventory/ansible_inventory.yml --connection ansible -p no:cacheprovider /home/.../ansible/roles/db/molecule/default/tests/test_default.py
^
WARNING  Retrying execution failure 127 of: pytest --ansible-inventory /home/.../.cache/molecule/db/default/inventory/ansible_inventory.yml --connection ansible -p no:cacheprovider /home/.../ansible/roles/db/molecule/default/tests/test_default.py
```

Тесты ожидают, что исполняемый файл `testinfra` называется `pytest`, а он у нас установлен с именем `pytest-3`. Сделаем символическую ссылку: `sudo ln -s /usr/bin/pytest-3 /usr/bin/pytest`.

Запускаем тесты ещё раз:
```console
> molecule verify
INFO     default scenario test matrix: verify
INFO     Performing prerun with role_name_check=0...
INFO     Running default > verify
INFO     Executing Testinfra tests found in /home/.../ansible/roles/db/molecule/default/tests/...
============================= test session starts ==============================
platform linux -- Python 3.10.4, pytest-6.2.5, py-1.10.0, pluggy-0.13.0
rootdir: /home/...
plugins: testinfra-6.5.0
collected 2 items

molecule/default/tests/test_default.py ..                                [100%]

============================== 2 passed in 3.67s ===============================
INFO     Verifier completed successfully.
```

Тесты прошли успешно.

Добавим проверку того, что сервис БД прослушивает порт 27017:
```python
import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')

# check if MongoDB is enabled and running
def test_mongo_running_and_enabled(host):
    mongo = host.service("mongodb")
    assert mongo.is_running
    assert mongo.is_enabled

# check if configuration file contains the required line
def test_config_file(host):
    config_file = host.file('/etc/mongodb.conf')
    assert config_file.contains('bindIp: 0.0.0.0')
    assert config_file.is_file

# check if MongoDB listen port 27017
def test_mongo_listen_port(host):
    mongo_socket = host.socket("tcp://0.0.0.0:27017")
    assert mongo_socket.is_listening
```

Проверяем:
```console
> molecule verify
INFO     default scenario test matrix: verify
INFO     Performing prerun with role_name_check=0...
INFO     Running default > verify
INFO     Executing Testinfra tests found in /home/.../ansible/roles/db/molecule/default/tests/...
============================= test session starts ==============================
platform linux -- Python 3.10.4, pytest-6.2.5, py-1.10.0, pluggy-0.13.0
rootdir: /home/...
plugins: testinfra-6.5.0
collected 3 items

molecule/default/tests/test_default.py ...                               [100%]

============================== 3 passed in 4.70s ===============================
INFO     Verifier completed successfully.
```

Тест проходит, порт прослушивается, отлично.
Далее нас просят использовать роли в db и app в плейбуках packer_db.yml (установка MongoDB) и packer_app.yml (установка Ruby).
Для начала проверим, работает ли конфигурация из прошлых домашних заданий: `packer validate -var-file=variables.json  db.json`.
Проверка прошла успешно, но мне пршлось исправить путь к плейбукам, т.к. мы их перемещали.
Меняем файл `packer_app.yml`, убираем задачи, добавляем роль:
```yaml
- name: Install base for application deploy
  hosts: all
  become: true

  roles:
    - app
```

Так, как нам нужно выполнить только установку `ruby`, то воспользуемся тегами. Всё, что касается установки, отмечено тегом `ruby`.
В плане тегов читаем официальную [документацию](https://www.packer.io/plugins/provisioners/ansible/ansible), после этого получим такой файл `app.json`:
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
            "image_name": "reddit-app-{{timestamp}}",
            "image_family": "reddit-app",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "../ansible/playbooks/packer_app.yml",
            "extra_arguments": [ "--tags", "ruby"]
        }
    ]
}
```

Пробуем собрать образ:
```console
> packer build -var-file=variables.json  app.json
yandex: output will be in this color.

==> yandex: Creating temporary RSA SSH key for instance...
==> yandex: Using as source image: fd8177ttrp7i4qqc75d6 (name: "ubuntu-16-04-lts-v20220801", family: "ubuntu-1604-lts")
==> yandex: Creating network...
==> yandex: Creating subnet in zone "ru-central1-a"...
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmog84indmfadbmk971 to become active...
    yandex: Detected instance IP: 62.84.114.111
==> yandex: Using SSH communicator to connect: 62.84.114.111
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with Ansible...
    yandex: Setting up proxy adapter for Ansible....
==> yandex: Executing Ansible: ansible-playbook -e packer_build_name="yandex" -e packer_builder_type=yandex --ssh-extra-args '-o IdentitiesOnly=yes' --tags ruby -e ansible_ssh_private_key_file=/tmp/ansible-key3143671882 -i /tmp/packer-provisioner-ansible992580919 /home/.../ansible/playbooks/packer_app.yml
    yandex: ERROR! the role 'app' was not found in /home/.../ansible/playbooks/roles:/home/.../.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:/home/.../ansible/playbooks
    yandex:
    yandex: The error appears to be in '/home/.../ansible/playbooks/packer_app.yml': line 7, column 7, but may
    yandex: be elsewhere in the file depending on the exact syntax problem.
    yandex:
    yandex: The offending line appears to be:
    yandex:
    yandex:   roles:
    yandex:     - app
    yandex:       ^ here
==> yandex: Provisioning step had errors: Running the cleanup provisioner, if present...
==> yandex: Destroying instance...
    yandex: Instance has been destroyed!
==> yandex: Destroying subnet...
    yandex: Subnet has been deleted!
==> yandex: Destroying network...
    yandex: Network has been deleted!
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' errored after 1 minute 28 seconds: Error executing Ansible: Non-zero exit status: exit status 1

==> Wait completed after 1 minute 28 seconds

==> Some builds didn't complete successfully and had errors:
--> yandex: Error executing Ansible: Non-zero exit status: exit status 1

==> Builds finished but no artifacts were created.
```

Сборщик не может найти роль. Выше видно, где он пытается её искать, но её там реально нет. [Подскажем](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-roles-path), при помощи переменных окружения `ansible`. Шаблон примет такой вид:
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
            "image_name": "reddit-app-{{timestamp}}",
            "image_family": "reddit-app",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "../ansible/playbooks/packer_app.yml",
            "extra_arguments": [ "--tags", "ruby"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH=../ansible/roles"]
        }
    ]
}
```

Собираем образ:
```console
> packer build -var-file=variables.json  app.json
yandex: output will be in this color.

==> yandex: Creating temporary RSA SSH key for instance...
==> yandex: Using as source image: fd8177ttrp7i4qqc75d6 (name: "ubuntu-16-04-lts-v20220801", family: "ubuntu-1604-lts")
==> yandex: Creating network...
==> yandex: Creating subnet in zone "ru-central1-a"...
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmba8u25iudfv8o176q to become active...
    yandex: Detected instance IP: 51.250.64.192
==> yandex: Using SSH communicator to connect: 51.250.64.192
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with Ansible...
    yandex: Setting up proxy adapter for Ansible....
==> yandex: Executing Ansible: ansible-playbook -e packer_build_name="yandex" -e packer_builder_type=yandex --ssh-extra-args '-o IdentitiesOnly=yes' --tags ruby -e ansible_ssh_private_key_file=/tmp/ansible-key1939102186 -i /tmp/packer-provisioner-ansible2160329206 /home/.../ansible/playbooks/packer_app.yml
    yandex:
    yandex: PLAY [Install base for application deploy] ***********************************************************************
    yandex:
    yandex: TASK [Gathering Facts] *******************************************************************************************
    yandex: ok: [default]
    yandex:
    yandex: TASK [app : Install packages for app base] ***********************************************************************
    yandex: changed: [default]
    yandex:
    yandex: TASK [app : Remove useless packages from the cache] **************************************************************
    yandex: changed: [default]
    yandex:
    yandex: TASK [app : Remove dependencies that are no longer required] *****************************************************
    yandex: ok: [default]
    yandex:
    yandex: PLAY RECAP *******************************************************************************************************
    yandex: default                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    yandex:
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-app-1660189627
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying subnet...
    yandex: Subnet has been deleted!
==> yandex: Destroying network...
    yandex: Network has been deleted!
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 3 minutes 5 seconds.

==> Wait completed after 3 minutes 5 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-1660189627 (id: fd836o0mp9hcpq0unage) with family name reddit-app
```

Всё прошло хорошо. Аналогично обновим файлы для сборки образа `db`.
Файл `cat packer_db.yml`:
```yaml
- name: Install base for database server
  hosts: all
  become: true

  roles:
    - db
```

Файл `db.json`:
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
            "image_name": "reddit-db-{{timestamp}}",
            "image_family": "reddit-db",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "../ansible/playbooks/packer_db.yml",
            "extra_arguments": [ "--tags", "install"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH=../ansible/roles"]
        }
    ]
}
```

Проверяем сборку образа:
```console
> packer build -var-file=variables.json db.json
yandex: output will be in this color.

==> yandex: Creating temporary RSA SSH key for instance...
==> yandex: Using as source image: fd8177ttrp7i4qqc75d6 (name: "ubuntu-16-04-lts-v20220801", family: "ubuntu-1604-lts")
==> yandex: Creating network...
==> yandex: Creating subnet in zone "ru-central1-a"...
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhm1b74fb6c22vnapqu4 to become active...
    yandex: Detected instance IP: 51.250.66.135
==> yandex: Using SSH communicator to connect: 51.250.66.135
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with Ansible...
    yandex: Setting up proxy adapter for Ansible....
==> yandex: Executing Ansible: ansible-playbook -e packer_build_name="yandex" -e packer_builder_type=yandex --ssh-extra-args '-o IdentitiesOnly=yes' --tags install -e ansible_ssh_private_key_file=/tmp/ansible-key3846119512 -i /tmp/packer-provisioner-ansible3368069999 /home/.../ansible/playbooks/packer_db.yml
    yandex:
    yandex: PLAY [Install base for database server] **************************************************************************
    yandex:
    yandex: TASK [Gathering Facts] *******************************************************************************************
    yandex: ok: [default]
    yandex:
    yandex: TASK [db : Install mongodb] **************************************************************************************
    yandex: changed: [default]
    yandex:
    yandex: TASK [db : Remove useless packages from the cache] ***************************************************************
    yandex: changed: [default]
    yandex:
    yandex: TASK [db : Remove dependencies that are no longer required] ******************************************************
    yandex: ok: [default]
    yandex:
    yandex: TASK [db : Enable mongodb service] *******************************************************************************
    yandex: ok: [default]
    yandex:
    yandex: PLAY RECAP *******************************************************************************************************
    yandex: default                    : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    yandex:
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-db-1660190159
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying subnet...
    yandex: Subnet has been deleted!
==> yandex: Destroying network...
    yandex: Network has been deleted!
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 3 minutes 26 seconds.

==> Wait completed after 3 minutes 26 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-db-1660190159 (id: fd8d08836d6u37qffj8f) with family name reddit-db
```

Прекрасно, образы собраны с использованием ролей.

**Результат №10-1:**
- Мы использовали Vagrant для локально разработки ролей
- Мы протестировали роли при помощи Molecule и Testinfra
- Мы использовали полученные роли для сбора образов при помощи Packer

---

**Задание №10-2:**
Вынести роль db в отдельный репозиторий: удалить роль из репозитория infra и сделать подключение роли через requirements.yml обоих окружений;

**Решение №10-2:**
Посмотрим, какие роли у нас присутствуют в системе. Для этого в каталоге `ansible` выполним `ansible-galaxy list`:
```console
> ansible-galaxy list
# /home/.../ansible/roles
- jdauphant.nginx, v2.21.1
- db, (unknown version)
- app, (unknown version)
```

Пока запакуем роль `db` в архив `tar jcvf db.tgz db` и удалим её из каталога локальных ролей.
Проверяем:
```console
> ansible-galaxy list
# /home/.../ansible/roles
- jdauphant.nginx, v2.21.1
- app, (unknown version)
```

Прекрасно. Теперь роль нужно внести в файлы `environments/stage/requirements.yml` и `environments/prod/requirements.yml`. Смотрим [документацию](https://galaxy.ansible.com/docs/using/installing.html) на предмет вариантов указания источника получения роли. Так как у нас учебный проект, то размещение на веб-сервере в архиве мне неплохо подходит. Созданный ранее архив разместим в каталоге `/tmp/webserver`. В комплекте с `python` есть модули для веб-сервера, воспользуемся ими. В соседней консоли запустим веб-сервер и проверим его работу:
```console
> cd /tmp/webserver && python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...

> wget http://localhost:8000/db.tgz
--2022-13-13 00:00:00--  http://localhost:8000/db.tgz
Resolving localhost (localhost)... 127.0.0.1
Connecting to localhost (localhost)|127.0.0.1|:8000... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3974 (3.9K) [application/x-tar]
Saving to: ‘db.tgz’

db.tgz               100%[===================>]   3.88K  --.-KB/s    in 0s

2022-13-13 00:00:13 (674 MB/s) - ‘db.tgz’ saved [3974/3974]
```

Теперь вносим в файл зависимостей нашу роль:
```yaml
- src: jdauphant.nginx
  version: v2.21.1

- src: http://localhost:8000/db.tgz
  name: db
```

Устанавливаем зависимости:
```console
> ansible-galaxy install -r environments/stage/requirements.yml
Starting galaxy role install process
- jdauphant.nginx (v2.21.1) is already installed, skipping.
- downloading role from http://localhost:8000/db.tgz
- extracting db to /home/.../ansible/roles/db
- db was installed successfully

> ansible-galaxy list
# /home/.../ansible/roles
- jdauphant.nginx, v2.21.1
- db, (unknown version)
- app, (unknown version)
```

Роль на месте.

---

**Результат №10-2:**
Мы вынесли роль `db` из репозитория и вернули её, как зависимость, через файл `requirements.yml`.
