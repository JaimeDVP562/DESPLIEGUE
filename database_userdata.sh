#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update -y
apt install mysql-server -y

# Esperar a que MySQL esté completamente activo para que no nos de problemas a la hora de conectarnos 
sleep 5

# Habilitamos mysql
systemctl enable mysql

# Ejecutar comandos SQL
mysql << EOF
CREATE DATABASE IF NOT EXISTS webapp;

CREATE USER IF NOT EXISTS 'webuser'@'%' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON webapp.* TO 'webuser'@'%';

CREATE USER IF NOT EXISTS 'webuser'@'localhost' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON webapp.* TO 'webuser'@'localhost';

USE webapp;
CREATE TABLE IF NOT EXISTS user (
    ID INT PRIMARY KEY,
    NAME VARCHAR(255)
);

FLUSH PRIVILEGES;
EOF
# Modificar configuración de MySQL para permitir conexiones externas
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciar MySQL para aplicar cambios
systemctl restart mysql