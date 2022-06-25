#!/bin/sh

apt-get update
apt -y upgrade
apt-get install -y apt-transport-https ca-certificates
apt-get install -y ruby-full ruby-bundler build-essential
