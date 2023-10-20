provider "aws" {
  region = "us-east-1"  
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/22"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "172.16.0.0/24"
  availability_zone       = "us-east-1a" 
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1b"  
}

resource "aws_subnet" "database_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "us-east-1b"  
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  route {
    cidr_block = "172.16.0.0/22"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "PublicRTAssociation"{
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  route {
    cidr_block = "172.16.0.0/22"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "PrivateRTAssociation"{
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table" "database_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "172.16.0.0/22"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "DatabaseRTAssociation"{
    subnet_id = aws_subnet.database_subnet.id
    route_table_id = aws_route_table.database_route_table.id
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_eip" "my_eip" {
  instance = null
}

resource "aws_instance" "public_instance" {
  ami           = "ami-041feb57c611358bd"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.public_sg.id]
  key_name      = "lab_key_pair" 
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_sg" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "private_inbound_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["172.16.0.0/22"]
  security_group_id = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "private_inbound_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["172.16.0.0/22"]
  security_group_id = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "database_inbound_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  source_security_group_id = aws_security_group.private_sg.id
  security_group_id = aws_security_group.database_sg.id
}

resource "aws_security_group_rule" "database_inbound_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  source_security_group_id = aws_security_group.private_sg.id
  security_group_id = aws_security_group.database_sg.id
}

resource "aws_security_group_rule" "public_inbound_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "public_inbound_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
}

resource "aws_instance" "private_instance" {
  ami           = "ami-041feb57c611358bd"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.private_sg.id]
  key_name      = "lab_key_pair" 
}

resource "aws_instance" "database_instance" {
  ami           = "ami-041feb57c611358bd" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.database_subnet.id
  security_groups = [aws_security_group.database_sg.id]
  key_name      = "lab_key_pair" 
}


