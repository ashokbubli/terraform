provider "aws" {
    region = "us-east-1"
  
}

# vpc creation
# subnet creation
# igw creation
# route table creation
# routable subnet association
# routes and gateway 

resource "aws_vpc" "app-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
      Name = "my-vpc"
    }
  
}

resource "aws_subnet" "ps" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true

    tags = {
      Name = "public-subnet"
    }
  
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.app-vpc.id

    tags = {
      Name = "external world connect"
    }
  
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.app-vpc.id

    tags = {
      Name = "route table"
    }
  
}

resource "aws_route_table_association" "subnet-association" {
    route_table_id = aws_route_table.rt.id
    subnet_id = aws_subnet.ps.id
  
}

resource "aws_route" "routes" {
    route_table_id = aws_route_table.rt.id
    gateway_id = aws_internet_gateway.igw.id
    destination_cidr_block = "0.0.0.0/0"
  
}



# key pair generation 
# security groups
# Ec2 creation with vpc

#https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
resource "tls_private_key" "rsa" {
    algorithm = "RSA"
    rsa_bits = 4096
  
}

#https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "private_key" {
    content = tls_private_key.rsa.private_key_pem
    filename = "server.pem"
  
}


resource "aws_key_pair" "key-pair" {
    key_name = "server"
    public_key = tls_private_key.rsa.public_key_openssh
    
  
}




resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.app-vpc.id

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
      Name = "app security group"
    }
  
}




resource "aws_instance" "ubuntu" {
    ami = "ami-0e86e20dae9224db8"
    instance_type = "t2.micro"
    key_name = aws_key_pair.key-pair.id
    security_groups = [aws_security_group.sg.id]
    subnet_id = aws_subnet.ps.id

    tags = {
      Name = "app_server"
    }

# https://developer.hashicorp.com/terraform/language/resources/provisioners/connection
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = local_file.private_key.content
      host = self.public_ip
    }




    provisioner "file" {
        source = "C:/Users/Admin/Desktop/github/app.py"
        destination = "/home/ubuntu/app.py"
      
    }

    provisioner "remote-exec" {
        inline = [ 
                "echo 'Hello from the remote instance'",
                "sudo apt update -y",  # Update package lists (for ubuntu)
                "sudo apt-get install -y python3-pip",  # Example package installation
                "cd /home/ubuntu",
                "sudo pip3 install flask",
                "sudo python3 app.py &",
        ]
      
    }

  
}

output "instance-public-ip" {
    value = aws_instance.ubuntu-1.public_ip
  
}




