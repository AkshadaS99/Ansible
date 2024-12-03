terraform {
required_providers {
aws = {
      source = "hashicorp/aws"
      version = "5.74.0"
    }
  }
}
provider "aws" {
  region = "us-west-2"
}
variable "sg_ports" {
  type        = list
  description = "list of ingress ports"
  default     = [22,80,8080,443]
}
resource "aws_security_group" "dynamicsg" {
  name        = "dynamic-sg"
  description = "Ingress for Vault"

  dynamic "ingress" {
    for_each = var.sg_ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "mykey"
  public_key = file("id_ed25519.pub")
#public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+hH81N7t/sQTYfBbcGqnVzil3RQ0BsD6iR/Gyybwoe Dell@DESKTOP-MDQ9LEM"
}

resource "aws_instance" "ec2instance" {
  ami           = "ami-055e3d4f0bbeb5878" 
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.key_name
  #associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.dynamicsg.id]
  tags = {
    Name = "pub1"
  }
provisioner "local-exec" {
    command = "echo ${aws_instance.ec2instance.private_ip} >> inventory.txt"
  }
}