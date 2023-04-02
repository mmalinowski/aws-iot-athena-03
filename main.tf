terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket  = "iot-analytics-terraform-state"
    key     = "terraform/iot-analytics/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = "true"
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      project    = "iot-analytics"
      managed-by = "Terraform"
    }
  }
}
