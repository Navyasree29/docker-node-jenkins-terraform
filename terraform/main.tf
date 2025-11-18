terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ecr_repository" "app_repo" {
  name = var.ecr_repository_name
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-ecr-pull-role-${substr(md5(timestamp()),0,6)}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${substr(md5(timestamp()),0,6)}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "node_sg" {
  name_prefix = "node-app-sg-"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "node_ec2" {
  ami                    = "ami-03695d52f0d883f65" # keep this if validated for ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.node_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install Docker & AWS CLI
    if command -v dnf >/dev/null 2>&1; then
      sudo dnf update -y
      sudo dnf install -y docker aws-cli
    else
      sudo yum update -y
      sudo yum install -y docker aws-cli
    fi

    sudo systemctl enable --now docker
    sudo usermod -a -G docker ec2-user

    sleep 5

    REPO_URL=${aws_ecr_repository.app_repo.repository_url}
    REGION=${var.region}
    
    # Extract registry host from repo URL in bash
    registry=$(echo $REPO_URL | cut -d'/' -f1)

    # Login to ECR
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $registry

    # Pull Docker image with retries
    for i in 1 2 3 4 5; do
      if docker pull ${REPO_URL}:latest; then
        break
      fi
      sleep 5
    done

    # Stop & remove existing container if present
    if docker ps -q -f name=node-app | grep -q .; then
      docker stop node-app || true
      docker rm node-app || true
    fi

    docker run -d --name node-app -p 80:3000 ${REPO_URL}:latest || true
  EOF

  tags = {
    Name = "nodejs-app-server"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "ec2_public_ip" {
  value = aws_instance.node_ec2.public_ip
}
