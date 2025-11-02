# Terraform and Provider Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = "CDF Asterisk"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Repository  = "cdf-asterisk"
    }
  }
}
