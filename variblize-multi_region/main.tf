resource "aws_instance" "server-1" {
    ami = var.ami-value
    instance_type = var.instance-type
    key_name = var.key-pair
    provider = aws.region1

    tags = {
      Name = var.server-1
    }
}

resource "aws_instance" "server-2" {
    ami = var.ami-value-2
    instance_type = var.instance-type-2
    key_name = var.key-pair-2
    provider = aws.region2

    tags = {
      Name = var.server-2
    }
}

