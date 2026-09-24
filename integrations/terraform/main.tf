terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "roche_engine" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "Roche-EVM-Security-Engine"
  }
}
