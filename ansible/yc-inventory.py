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
