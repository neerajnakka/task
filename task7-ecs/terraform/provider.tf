terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # We will use S3 backend for this task as well, utilizing the SAME bucket but a DIFFERENT key
  backend "s3" {
    bucket = "neeraj-strapi-task-state"
    key    = "task7-fargate/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
}
