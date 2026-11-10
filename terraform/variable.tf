variable "region" {
  description = "AWS region to deploy resources in"
}

variable "vpc-cidr" {
  description = "Virtual private cloud cidr"
}

variable "public-subnet-cidr" {
  description = "Public subnet cidr" 
}

variable "default_route" {
  description = "Default route"
}

variable "my_public_ip" {
  description = "My public ip"
}

variable "instance_type" {
  description = "Instance resources type"
}

variable "key_pair" {
  description = "The key used in ssh process"
}