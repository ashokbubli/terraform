module "ec2" {
    source = "D:/tf/variablise-project/ec2"
    region1 = var.region1
    ami-1 = var.ami-1
    instance-type = var.instance-type
    key-pair = var.key-pair
    server-name =var.server-name
  
}