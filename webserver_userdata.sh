#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install apache2 -y
apt install mysql-client -y

# Instalamos php por si acaso
apt install php8.1 php8.1-mysql libapache2-mod-php8.1 -y
# Deshabilitamos el autoindex para que no 
a2dismod autoindex

# Configuramos el VirtualHost principal
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Creamos una pagina de prueba
echo "<html><head><title>Proyecto Terraform</title></head><body><h1>Jaime Gavilan Torrero</h1></body></html>" > /var/www/html/index.html

# Habilitamos el apache y lo restablecemos por si acaso
systemctl enable apache2
systemctl start apache2