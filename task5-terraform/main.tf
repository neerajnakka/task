terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "neeraj-strapi-task-state"
    key    = "strapi/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---
# Get default VPC and Subnets to deploy into
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Groups ---

# 1. App Security Group (EC2)
resource "aws_security_group" "app_sg" {
  name        = "neeraj-strapi-app-sg-v2"
  description = "Allow HTTP and Strapi traffic"
  vpc_id      = data.aws_vpc.default.id

  # SSH for EC2 Instance Connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Strapi Default Port
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule (allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = "ap-south-1"
  
  # Networking
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  # Tags
  tags = {
    Name = "neeraj-strapi-v2"
  }

  # User Data Script to Install Docker and Run Strapi
  user_data = templatefile("${path.module}/install_strapi.sh.tpl", {
    # We no longer need db_host from RDS, we pass internal variables for the local container
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
  })
}

# --- Outputs ---
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}
