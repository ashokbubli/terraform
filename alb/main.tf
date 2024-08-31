resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "app vpc"
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

resource "aws_route_table_association" "subnet-association1" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.s1.id
  
}
resource "aws_route_table_association" "subnet-association2" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.s2.id
  
}

resource "aws_route" "routes" {
  route_table_id = aws_route_table.rt.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "private_key" {
  content = tls_private_key.rsa.private_key_pem
  filename = "serverkey.pem"
}

resource "aws_key_pair" "kp" {
  
  key_name = "serverkey"
  public_key = tls_private_key.rsa.public_key_openssh
}


resource "aws_security_group" "sg" {
  name = "my-sg"
  vpc_id = aws_vpc.my-vpc.id

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
  
}

resource "aws_instance" "server1" {
  ami = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.sg.id]
  key_name = aws_key_pair.kp.id
  subnet_id = aws_subnet.s1.id
  user_data = base64encode(file("userdata.sh"))

  tags = {
    Name = "server-1"
  }
}

resource "aws_instance" "server2" {
  ami = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.sg.id]
  key_name = aws_key_pair.kp.id
  subnet_id = aws_subnet.s2.id
  user_data = base64encode(file("userdata1.sh"))

  tags = {
    Name = "server-2"
  }
}


resource "aws_lb" "my-alb" {
  name = "my-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg.id]
  subnets = [aws_subnet.s1.id, aws_subnet.s2.id]

  tags = {
    Name = "my alb"
  }
  
}

resource "aws_lb_target_group" "albt" {
  name = "my-alb-target-group"
  port = "80"
  protocol = "HTTP"
  vpc_id = aws_vpc.my-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "albta1" {
  target_group_arn = aws_lb_target_group.albt.arn
  target_id = aws_instance.server1.id
  port = 80
  
}

resource "aws_lb_target_group_attachment" "albta2" {
  target_group_arn = aws_lb_target_group.albt.arn
  target_id = aws_instance.server2.id
  port = 80
  
}

resource "aws_lb_listener" "albl" {
  load_balancer_arn = aws_lb.my-alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.albt.arn
  }
  
}

output "dns" {
  value = aws_lb.my-alb.dns_name
}























