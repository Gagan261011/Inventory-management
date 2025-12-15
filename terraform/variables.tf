variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project Name"
  default     = "inventory-demo"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into nodes"
  default     = "0.0.0.0/0" # WARNING: Change this for production
}

variable "key_name" {
  description = "EC2 Key Pair Name"
  default     = "inventory-key"
}

variable "public_key_path" {
  description = "Path to public key to import (optional)"
  default     = "~/.ssh/id_rsa.pub"
}
