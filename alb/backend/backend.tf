terraform {
  backend "s3" {
    bucket = "abd-terraform-project-backend-test222"
    key    = "state-file/terraform.tfstate"
    region = "us-east-1"
  }
}
