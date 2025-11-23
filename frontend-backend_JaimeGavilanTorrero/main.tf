// -------------------------------------------------------------
// Infraestructura básica en AWS siguiendo la filosofía del cole:
// - Security Groups creados solo con nombre y descripción.
// - TODAS las reglas de ingreso/salida creadas aparte.
// - Bastion con SSH desde Internet.
// - Frontend: HTTP desde Internet + SSH solo desde bastion.
// - Backend: HTTP solo desde frontend + SSH desde bastion.
// -------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.22.1"
    }
  }
}

provider "aws" {
  region = var.region
}

// GRUPOS DE SEGURIDAD 

//GRUPOD DE SEGURIDAD BASTION
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Security group for bastion host"
}
// GRUPO DE SEGURIDAD FRONTEND
resource "aws_security_group" "frontend" {
  name        = "frontend"
  description = "Security group for frontend server"
}
// GRUPO DE SEGURIDAD BACKEND
resource "aws_security_group" "backend" {
  name        = "backend"
  description = "Security group for backend server"
}

// REGLAS DE SEGURIDAD PARA EL BASTION

// Ingreso SSH desde cualquier IP
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

// REGLA DE SALIDA LIBRE
resource "aws_vpc_security_group_egress_rule" "bastion_egress_all" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

// REGLAS DE SEGURIDAD PARA EL FRONTEND

// REGLA DE INGRESO SSH únicamente desde bastion
resource "aws_vpc_security_group_ingress_rule" "frontend_ssh" {
  security_group_id            = aws_security_group.frontend.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id
}
// REGLA DE INGRESO HTTP desde Internet
resource "aws_vpc_security_group_ingress_rule" "frontend_http" {
  security_group_id = aws_security_group.frontend.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

// REGLA DE SALIDA LIBRE 
resource "aws_vpc_security_group_egress_rule" "frontend_egress_all" {
  security_group_id = aws_security_group.frontend.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

// REGLAS DE SEGURIDAD PARA EL BACKEND

// REGLA DE INGRESO SSH desde bastion
resource "aws_vpc_security_group_ingress_rule" "backend_ssh" {
  security_group_id            = aws_security_group.backend.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id
}

// REGLA DE INGRESO HTTP desde frontend
resource "aws_vpc_security_group_ingress_rule" "backend_http" {
  security_group_id            = aws_security_group.backend.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.frontend.id
}

// REGLA DE SALIDA LIBRE
resource "aws_vpc_security_group_egress_rule" "backend_egress_all" {
  security_group_id = aws_security_group.backend.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

// CREAMOS LAS INSTANCIAS

// INSTANCIA BASTION
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = { Name = "Bastion" }
}

// INSTANCIA FRONTEND
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.frontend.id]

  tags = { Name = "Frontend" }
}
// INSTANCIA BACKEND
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.backend.id]

  tags = { Name = "Backend" }
}

// DNS Route53

// ZONA ALOJADA EN ROUTE53
resource "aws_route53_zone" "main_zone" {
  name = var.domain
}
// REGISTROS DNS PARA FRONTEND
resource "aws_route53_record" "frontend_record" {
  zone_id = aws_route53_zone.main_zone.zone_id
  name    = "fe.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.frontend.public_ip]
}
// REGISTROS DNS PARA BACKEND
resource "aws_route53_record" "backend_record" {
  zone_id = aws_route53_zone.main_zone.zone_id
  name    = "be.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.backend.private_ip]
}