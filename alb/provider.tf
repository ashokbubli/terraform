terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}

provider "aws" {
    region = "us-east-1"
  
}