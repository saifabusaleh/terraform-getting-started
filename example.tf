##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "eu-south-1"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}


#####


resource "tls_private_key" "webserver_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "private_key" {
  content         = tls_private_key.webserver_private_key.private_key_pem
  filename        = "webserver_key.pem"
  file_permission = 0400
}
resource "aws_key_pair" "webserver_key" {
  key_name   = "webserver"
  public_key = tls_private_key.webserver_private_key.public_key_openssh
}

##################################################################################
# RESOURCES
##################################################################################


resource "aws_security_group" "allow_ssh" {
  name        = "nginx_demo"
  description = "Allow ports for nginx demo"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = "ami-09e1a48112c81cec6"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.webserver_key.key_name
  security_groups       = [aws_security_group.allow_ssh.name]


  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = aws_instance.nginx.public_ip
    port        = 22
    private_key = tls_private_key.webserver_private_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo amazon-linux-extras enable nginx1",
      "sudo yum -y install nginx",
      "sudo service nginx start"
    ]
  }
}

##################################################################################
# OUTPUT
##################################################################################

output "aws_instance_public_dns" {
  value = aws_instance.nginx.public_dns
}