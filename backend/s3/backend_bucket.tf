

resource "aws_s3_bucket" "bucket" {
    bucket = "abd-terraform-project-backend-test222"

    tags = {
      Name = "tf backend"
    }
  
}