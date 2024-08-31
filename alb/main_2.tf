#alb with provisioners

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my vpc"
  }
  
}

resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet 1"
  }
  
}

resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

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

resource "aws_route_table_association" "sub-association-1" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.sub1.id
  
}

resource "aws_route_table_association" "sub-association-2" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.sub2.id
  
}

resource "aws_route" "route" {
  route_table_id = aws_route_table.rt.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}


resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.my-vpc.id
  name = "my-security-group"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port = 22
    to_port = 22
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
    Name = "my-security-group"
  }
  
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
  
}

resource "local_file" "privatekey" {
  content = tls_private_key.rsa.private_key_pem
  filename = "serverkey.pem"
  
}

resource "aws_key_pair" "kp" {
  key_name = "serverkey"
  public_key = tls_private_key.rsa.public_key_openssh
  
}

resource "aws_instance" "server1" {
  ami = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  key_name = aws_key_pair.kp.id
  security_groups = [aws_security_group.sg.id]
  subnet_id = aws_subnet.sub1.id
  
  tags = {
    Name = "server 1"
  }
    connection {
    type = "ssh"
    user = "ubuntu"
    private_key = local_file.privatekey.content
    host = self.public_ip
  }

  provisioner "file" {
    source = "D:/tf/project-1/userdata.sh"
    destination = "/home/ubuntu/userdata.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod 777 userdata.sh",
      "sudo ./userdata.sh",
     ]
    
  }
}


resource "aws_instance" "server2" {
  ami = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  key_name = aws_key_pair.kp.id
  security_groups = [aws_security_group.sg.id]
  subnet_id = aws_subnet.sub2.id
  
  tags = {
    Name = "server 2"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = local_file.privatekey.content
    host = self.public_ip
  }

  provisioner "file" {
    source = "D:/tf/project-1/userdata1.sh"
    destination = "/home/ubuntu/userdata1.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod 777 userdata1.sh",
      "sudo ./userdata1.sh",
     ]
    
  }
}

output "public_ip1" {
  value = aws_instance.server1.public_ip
  
}

output "public_ip2" {
  value = aws_instance.server2.public_ip
  
}


##########################
### ALB #################

resource "aws_lb" "my-alb" {
  name = "my-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg.id]
  subnets = [ aws_subnet.sub1.id, aws_subnet.sub2.id ]
  
  tags = {
    Name = "my alb"
  }
}

resource "aws_lb_target_group" "my-alb-target-group" {
  name = "my-alb"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.my-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }

}

resource "aws_lb_target_group_attachment" "attach-server-1" {
  target_group_arn = aws_lb_target_group.my-alb-target-group.arn
  target_id = aws_instance.server1.id
  port = 80
  
}

resource "aws_lb_target_group_attachment" "attach-server-2" {
  target_group_arn = aws_lb_target_group.my-alb-target-group.arn
  target_id = aws_instance.server2.id
  port = 80
}

resource "aws_lb_listener" "lb-listerner" {
  load_balancer_arn = aws_lb.my-alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my-alb-target-group.arn
  }
  
}

output "dns" {
  value = aws_lb.my-alb.dns_name
  
}

