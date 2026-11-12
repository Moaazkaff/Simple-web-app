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

import {
  to = aws_vpc.my-vpc
  identity = {
    id = "vpc-09eeed92514525244"
  }
}

import {
  to = aws_subnet.public-subnet
  identity = {
    id = "subnet-07415dd6c7fafb2c4"
  }
}

resource "aws_vpc" "my-vpc" {
    cidr_block = var.vpc-cidr
    tags = {
        Name = "MY-VPC"
    }

    lifecycle {
      prevent_destroy = true
    }
}

resource "aws_subnet" "public-subnet" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.public-subnet-cidr
    map_public_ip_on_launch = true
    tags = {
        Name = "Public-1A"
    }

    lifecycle {
      prevent_destroy = true
    }
}

resource "aws_security_group" "ec2-jenkins" {
  vpc_id = aws_vpc.my-vpc.id
  name = "ec2-jenkins"
  description = "Allow port port 80 , 22 , 8080 inbound and all outbound trafic"


}

resource "aws_vpc_security_group_ingress_rule" "rule1" {
  security_group_id = aws_security_group.ec2-jenkins.id
  cidr_ipv4         = var.default_route
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80


}

resource "aws_vpc_security_group_ingress_rule" "rule2" {
  security_group_id = aws_security_group.ec2-jenkins.id
  cidr_ipv4 = var.my_public_ip
  from_port = 8080
  to_port = 8080
  ip_protocol = "tcp"


}

resource "aws_vpc_security_group_ingress_rule" "rule3" {
  security_group_id = aws_security_group.ec2-jenkins.id
  to_port = 22
  from_port = 22
  ip_protocol = "tcp"
  cidr_ipv4 = var.my_public_ip


}

resource "aws_vpc_security_group_egress_rule" "all-outbound" {
  security_group_id = aws_security_group.ec2-jenkins.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"


}

resource "aws_instance" "jenkins_ec2" {
  subnet_id = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.ec2-jenkins.id ]
  instance_type = var.instance_type
  ami = data.aws_ami.ubuntu.id
  key_name = var.key_pair
  tags = {
    Name = "jenkins-ec2" 
  }
}