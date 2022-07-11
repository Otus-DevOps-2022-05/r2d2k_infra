#!/bin/sh

sudo sed -i s/127.0.0.1/0.0.0.0/ /etc/mongodb.conf
sudo systemctl restart mongodb
