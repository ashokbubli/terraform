terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.65.0"
    }
  }
}

provider "aws" {
    region = var.region-1
    alias = "region1"
  
}

provider "aws" {
    region = var.region-2
    alias = "region2"
  
}