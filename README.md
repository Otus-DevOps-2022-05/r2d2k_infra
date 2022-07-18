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
