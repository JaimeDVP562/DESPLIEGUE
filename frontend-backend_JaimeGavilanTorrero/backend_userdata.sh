#!/bin/bash
apt-get update -y
apt-get install -y apache2 php libapache2-mod-php php-mysql
systemctl enable apache2
systemctl start apache2
