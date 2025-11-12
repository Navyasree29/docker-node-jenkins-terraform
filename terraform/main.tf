provider "aws" {
  region = var.aws_region
}

# data for account id
data "aws_caller_identity" "current" {}

# ECR repo
#resource "aws_ecr_repository" "app_repo" {
#  name = var.app_name
#}

# Use existing ECR repository instead of creating
data "aws_ecr_repository" "app_repo" {
  name = var.app_name
}


# Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow http inbound"
  vpc_id      = data.aws_vpcs.default.ids[0]

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

# Get default VPC (simple for beginners)
data "aws_vpcs" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM role and instance profile so EC2 can access ECR (pull)
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.app_name}-instance"
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    region       = var.aws_region
    account_id   = data.aws_caller_identity.current.account_id
    repo_name    = data.aws_ecr_repository.app_repo.name
    image_tag    = var.ecr_image_tag
  })
}

output "app_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ecr_repo_url" {
  value = data.aws_ecr_repository.app_repo.repository_url
}
