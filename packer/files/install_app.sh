#!/bin/sh

apt-get install -y git mc htop tmux
mkdir /app
cd /app
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

cp -f /tmp/reddit-app.service /etc/systemd/system/reddit-app.service
rm /tmp/reddit-app.service

systemctl daemon-reload
systemctl enable reddit-app.service
systemctl start reddit-app.service
