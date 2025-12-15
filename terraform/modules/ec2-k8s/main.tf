variable "project_name" {}
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "instance_type" { default = "t3.medium" }
variable "key_name" {}
variable "allowed_ssh_cidr" {}
variable "instance_profile_name" {}
variable "master_userdata" {}
variable "worker_userdata" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "k8s_sg" {
  name        = "${var.project_name}-k8s-sg"
  description = "Security group for K8s cluster"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP/HTTPS (NodePort/Ingress)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal communication
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "master" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_ids[0]
  key_name             = var.key_name
  iam_instance_profile = var.instance_profile_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data            = var.master_userdata

  tags = {
    Name = "${var.project_name}-master"
    Role = "master"
  }
}

resource "aws_instance" "worker" {
  count                = 2
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_ids[count.index % length(var.subnet_ids)]
  key_name             = var.key_name
  iam_instance_profile = var.instance_profile_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data            = var.worker_userdata

  tags = {
    Name = "${var.project_name}-worker-${count.index}"
    Role = "worker"
  }
}

output "master_public_ip" { value = aws_instance.master.public_ip }
output "master_private_ip" { value = aws_instance.master.private_ip }
output "worker_public_ips" { value = aws_instance.worker[*].public_ip }
