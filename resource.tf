# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}

# Create Public subnet under main vpc
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Public Subnet"
  }
}

# Create Private subnet under main vpc
resource "aws_subnet" "Private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "Private Subnet"
  }
}

# Create internet gatewat under main vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Internet GateWay"
  }
}

# Create route table for public subnet with internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Route Table"
  }
}

# associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Create security group with inbound and outbound ports open under main VPC
resource "aws_security_group" "ssh_access" {
  name_prefix = "SSH-and-HTTP-access"
  vpc_id      = aws_vpc.main.id
  # inbound port 80
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  # inbound port 22
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  # outbound port all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create instance with server installed and a simple webpage running.
resource "aws_instance" "web_server" {
  ami                    = var.ami
  instance_type          = var.instanceType
  key_name               = var.keyName
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  tags = {
    Name = "Web Server"
  }
  user_data = <<EOF
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo '<div style="text-align: center;font-family: arial;color: red;"><h1>Welcome to my website <br />New instance created by Neel - Your DevOps Guy</h1></div>' > /var/www/html/index.html
sudo systemctl restart httpd
  EOF
}

# Create Elastic IP and attach it to the instance
resource "aws_eip" "elastic_ip" {
  instance = aws_instance.web_server.id
  tags = {
    Name = "webserver-eip"
  }
}

# Display IP address of the instance in the CLI
output "getIP" {
  value = aws_instance.web_server.public_ip
}
