terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

// Creamos el grupo de seguridad SSH
resource "aws_security_group" "ssh" {
  name        = "ssh-demo-lamp"
  description = "Allow SSH traffic"
}

// Creamos la regla de entrada que permite el trafico desde el puerto 22
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = 22
  from_port         = 22
  ip_protocol       = "TCP"
  security_group_id = aws_security_group.ssh.id
}
// Creamos otro grupo de seguridad 
resource "aws_security_group" "all" {
  name        = "all-demo-lamp"
  description = "Allow Egress traffic"
}

// Creamos una regla de salida para el grupo de seguridad All --> IMPORTANTE -> Cuando creemos un grupo de seguridad tenemos que asociarlo en la instancia
resource "aws_vpc_security_group_egress_rule" "all" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.all.id
}

// Cuando creemos un grupo de seguridad es mejor hacer un destroy y volver a crearla

// Creamos otro grupo de seguridad 
resource "aws_security_group" "http" {
  name        = "http-demo-lamp"
  description = "Allow http traffic"
}

// Creamos una regla de entrada para el grupo de seguridad All --> IMPORTANTE -> Cuando creemos un grupo de seguridad tenemos que asociarlo en la instancia
resource "aws_vpc_security_group_ingress_rule" "http" {
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = 80
  from_port         = 80
  ip_protocol       = "TCP"
  security_group_id = aws_security_group.http.id
}

// Creamos otro grupo de seguridad vacio para poder comunicar el servidor de base de datos con el servidor web
resource "aws_security_group" "wsmysql" {
  name        = "wsmysql-demo-lamp"
  description = "Identity Web Server connecti to db"
}
resource "aws_security_group" "db" {
  name        = "db-demo-lamp"
  description = "Allow MySQL Ingress traffic"
}

// Creamos una regla de entrada para el grupo de seguridad All --> IMPORTANTE -> Cuando creemos un grupo de seguridad tenemos que asociarlo en la instancia
resource "aws_vpc_security_group_ingress_rule" "db" {
  referenced_security_group_id = aws_security_group.wsmysql.id
  to_port                      = 3306
  from_port                    = 3306
  ip_protocol                  = "TCP"
  security_group_id            = aws_security_group.db.id
}

// Creamos una nueva instancia 
resource "aws_security_group" "nuevaInstancia" {
  name        = "nuevaInstancia"
  description = "NuevaInstancia: allow SSH from anywhere"
}

// Nueva regla para el grupo de seguridad
resource "aws_vpc_security_group_ingress_rule" "nuevaReglaNuevaInstancia" {
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = 22
  from_port         = 22
  ip_protocol       = "TCP"
  security_group_id = aws_security_group.nuevaInstancia.id
}
// Regla para conectar el nuevo grupo con el grupo que teniamos antes 
resource "aws_vpc_security_group_ingress_rule" "web_ssh_from_nuevaInstancia" {
  referenced_security_group_id = aws_security_group.nuevaInstancia.id
  to_port                      = 22
  from_port                    = 22
  ip_protocol                  = "TCP"
  security_group_id            = aws_security_group.ssh.id
}

// Creamos la instancia del servidor
resource "aws_instance" "webserver" {
  ami                    = "ami-0360c520857e3138f" // ami = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.small" // "t2.large"
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.all.id, aws_security_group.http.id, aws_security_group.wsmysql.id]
  tags = {
    "Name" = "DEMO Lamp"
  }
  user_data                   = file("webserver_userdata.sh")
  user_data_replace_on_change = true
}
// una vez llegados a este paso tenemos que irnos dentro de aws y conectar la instancia 
// sudo systemctl status apache2 --> (no va a funcionar) --> cd /tmp/ --> ls --> tail userdata.log --> (creamos el userdata-log) --> nano userdata.log 
// Creamos la regla de entrada que permite el trafico desde el puerto 22



// Cuando creemos todos los grupos de seguridad vamos a aws y comprobamos que es lo que ha creado
// Volvemos a la instancia dentro y comporobamos con --> sudo systemctl status apache2

// Ahora nos vamos a tener que ir a la instancia y una vez dentro de ella tenemos que buscar la DNS público

// Creamos la instancia de la base de datos
resource "aws_instance" "dbserver" {
  ami                    = "ami-0360c520857e3138f"// ami = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.small" // "t2.large"
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.all.id, aws_security_group.db.id]
  tags = {
    "Name" = "DEMO Lamp BBDD"
  }
  user_data                   = file("database_userdata.sh")
  user_data_replace_on_change = true
}
// Despues de crear el database_userdata.sh creamos la instancia de nuestro servidor de base de datos

resource "aws_instance" "nuevaInstancia" {
  ami           = "ami-XXXXXXXXXXXX" // ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.small"// "t2.large"
  key_name      = "vockey"
  vpc_security_group_ids = [aws_security_group.nuevaInstancia.id]
  tags = {
    "Name" = "NuevaInstancia"
  }
}


//  ASOCIACIÓN DE IP ELÁSTICA PARA WEBSERVER


// Creamos una IP elástica reservada para el servidor web
resource "aws_eip" "web_eip" {
  domain = "vpc"
  tags = {
    "Name" = "WebServer-EIP"
  }
}

// Asociamos esa IP elástica al webserver (para que nunca cambie)
resource "aws_eip_association" "web_eip_assoc" {
  instance_id   = aws_instance.webserver.id
  allocation_id = aws_eip.web_eip.id
}


// Una vez creado vamos a la instancia y nos conectamos y comprobamos que está el servicio corriendo --> sudo systemctl status mysql.service
// comprobamos que nos podemos conectar --> mysql -u webuser -p 
// Siguiente paso es ver las databases que tenemos --> show databases;
// Salimos de la database --> exit;

// Entramos a mysql --> sudo mysql
// Ahora volvemos a ver las databases que tenemos --> show databases;

// Volvemos a entrar con el usuario y contraseña --> mysql -u webuser -p --> secret(contraseña)
// Volvemos a usar la database con --> use webapp;
// sudo systemctl mysql.service --> (comprobamos que esté funcionando el servicio de la base de datos)
// mysql -u webuser -p --> secret (contraseña) --> (una vez entremos) 
// show databases; 
// --> use webapp;
// --> show tables; 
// --> exit;
// --> describe table user;
// --> show table user;
// SELECT * FROM USER;


// Despues de haber creado  trasteado todo el servidor donde tenemos la base de datos volvemos al servidor web
// Como conectar el servidor web a al servidorDB 
// Volvemos a la instancia de del servidor de la base de datos y volvemos a conectarnos 
// Para conectarnos desde el servidor de base de datos --> mysql -u webuser -p -h 172.31.30.158 -P 3306

