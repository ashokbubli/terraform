resource "aws_instance" "server1" {
    ami = var.ami-1
    instance_type = var.instance-type
    key_name = var.key-pair

    tags = {
      Name = var.server-name
    }
  
}