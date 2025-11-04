#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install apache2 -y
apt install mysql-client -y

systemctl enable apache2
systemctl start apache2