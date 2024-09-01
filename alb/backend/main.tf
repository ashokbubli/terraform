# vpc creation

resource "aws_vpc" "my-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
      Name = "my vpc"
    }
}

resource "aws_subnet" "s1" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
      Name = "subnet 1"
    }
}

resource "aws_subnet" "s2" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true

    tags = {
      Name = "subnet 2"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my-vpc.id

    tags = {
      Name = "internet gateway"
    }
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.my-vpc.id

    tags = {
      Name = "route table"
    } 
}

resource "aws_route_table_association" "subnet-association-1" {
    route_table_id = aws_route_table.rt.id
    subnet_id = aws_subnet.s1.id
}

resource "aws_route_table_association" "subnet-association-2" {
    route_table_id = aws_route_table.rt.id
    subnet_id = aws_subnet.s2.id
}

resource "aws_route" "route" {
    route_table_id = aws_route_table.rt.id
    gateway_id = aws_internet_gateway.igw.id
    destination_cidr_block = "0.0.0.0/0"
}


# security group

resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.my-vpc.id
    name = "my-sg"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "my security group"
    }
}

# key pair creation

resource "tls_private_key" "rsa" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "privatekey" {
    content = tls_private_key.rsa.private_key_pem
    filename = "serverconnect.pem"
}

resource "aws_key_pair" "kp" {
    key_name = "serverconnect"
    public_key = tls_private_key.rsa.public_key_openssh
}


# ec2 instance creation

# creation and run script with userdata
resource "aws_instance" "server-1" {
    ami = "ami-0e86e20dae9224db8"
    instance_type = "t2.micro"
    key_name = aws_key_pair.kp.id
    security_groups = [aws_security_group.sg.id]
    subnet_id = aws_subnet.s1.id
    user_data = base64encode(file("userdata1.sh"))

    tags = {
      Name = "server-1"
    }
  
}

# creation and run script with provisioners
resource "aws_instance" "server-2" {
    ami = "ami-0e86e20dae9224db8"
    instance_type = "t2.micro"
    key_name = aws_key_pair.kp.id
    security_groups = [aws_security_group.sg.id]
    subnet_id = aws_subnet.s2.id

    tags = {
      Name = "server-2"
    }

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = local_file.privatekey.content
      host = self.public_ip
    }

    provisioner "file" {
        source = "D:/tf/variablise-project/userdata.sh"
        destination = "/home/ubuntu/userdata.sh"
    }

    provisioner "remote-exec" {
        inline = [ 
            "sudo chmod 777 userdata.sh",
            "sudo ./userdata.sh",
         ]
    } 
}

# print public ip

output "server-1_ip" {
    value = aws_instance.server-1.public_ip
}

output "server-2_ip" {
    value = aws_instance.server-2.public_ip
}


# elb configuration

resource "aws_lb" "elb" {
    name = "aelb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.sg.id]
    subnets = [aws_subnet.s1.id, aws_subnet.s2.id] 
}

resource "aws_lb_target_group" "elbt" {
    name = "aelbt"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.my-vpc.id

    health_check {
      path = "/"
      port = "traffic-port"
    }
}

resource "aws_lb_target_group_attachment" "subnet1-attach" {
    target_group_arn = aws_lb_target_group.elbt.arn
    target_id = aws_instance.server-1.id
    port = 80
}

resource "aws_lb_target_group_attachment" "subnet2-attach" {
    target_group_arn = aws_lb_target_group.elbt.arn
    target_id = aws_instance.server-2.id
    port = 80
}

resource "aws_lb_listener" "elbl" {
    load_balancer_arn = aws_lb.elb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.elbt.arn
    } 
}

# pint dns
output "dns" {
    value = aws_lb.elb.dns_name 
}