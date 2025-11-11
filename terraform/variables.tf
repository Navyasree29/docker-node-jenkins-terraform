variable "aws_region" {
  type    = string
  default = "ap-south-1"   
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_name" {
  type    = string
  default = "my-node-app"
}

variable "ecr_image_tag" {
  type    = string
  default = "latest"
}

variable "public_key" {
  description = "Optionally provide SSH public key to access EC2"
  type        = string
  default     = "capstone-deploy-key"   # optional, you can pass key pair name instead
}
