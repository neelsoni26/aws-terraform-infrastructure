# aws-terraform-infrastructure
Building AWS Infrastructure with Infrastructure as Code (Terraform) 🚀

## Prerequisite
- AWS IAM User and policies attached - Refer: [click here](https://neel-soni.hashnode.dev/aws-iam-create-user-add-to-group-and-attach-policies)
- AWS CLI installed and configured - Refer: [click here](https://neel-soni.hashnode.dev/iam-programmatic-access-and-aws-cli) 

After completion of the configuration continue on code editor with terraform.

**Tasks:**

**Basic structure:**

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
```

### 1: Create a VPC (Virtual Private Cloud) with CIDR block 10.0.0.0/16

```
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}
```

`aws_vpc` will create a VPC with specified cidr block and with tag name as main.

Run `terraform init` and then `terraform apply` then verify the creation of VPC in cosole.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705070734244/258f8be9-04b2-4a0b-9801-b0702356abc8.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705070865032/b8370036-289d-4fe5-b698-7fe3d8c2452a.png)

The VPC with name main has been created!

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705071131413/f46704d9-1c75-4a8f-94ce-5877cf2748b6.png)

### 2: Create a public subnet with CIDR block 10.0.1.0/24 in the above VPC.

Write below code to create aws subnet in the vpc that we just created.

```
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Public Subnet"
  }
}
```

After adding code, run `terraform apply` and verify subnet in cosole.

Check "Public Subnet" is created successfully.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705071816689/3e64d976-4d2a-4a1e-ab19-2e471943bc04.png)

### 3: Create a private subnet with CIDR block 10.0.2.0/24 in the above VPC.

Write below code to create aws subnet in the vpc that we just created.

```
resource "aws_subnet" "Private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "Private Subnet"
  }
}
```

After adding code, run `terraform apply` and verify subnet in cosole.

Check "Private Subnet" is created successfully.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705072022087/24af29a5-5bba-4030-a3b5-94454c74357c.png)

### 4: Create an Internet Gateway (IGW) and attach it to the VPC

```
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Internet GateWay"
  }
}
```

`aws_internet_gateway` will create an internet gateway and will be under VPC `main` as `vpc_id` has been assigned of `main` VPC.

After adding code, run `terraform apply` and verify internet gateway in cosole.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705072466979/a807cb0e-6f4e-4d04-9ecf-cc62614bd226.png)

### 5: Create a route table for the public subnet and associate it with the public subnet. This route table should have a route to the Internet Gateway.

Create a route table for public subnet

```
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
```

aws\_route\_table will create a table under vpc main. The route will sends all the traffic with specified cidr to the internet gateway.

Then associate route table with public subnet.

```
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}
```

`aws_route_table_association` will associate the route table to the public subnet.

After adding code, run terraform apply and verify route table in cosole.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705073336577/b367f970-cc28-4094-aa61-c2e17eee71aa.png)

In Route tables, new route table is successfully created.

Route table routes with internet gateway.

Route table is associated with public subnet using terraform.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705073528784/149ec42a-8756-41e3-9b61-005a670a4e3f.png)

### 7:Launch an EC2 instance in the public subnet with the following details:

\- AMI  
\- Instance type: t2.micro  
\- Security group: Allow SSH access from anywhere  
\- User data: Use a shell script to install Apache and host a simple website  
\- Create an Elastic IP and associate it with the EC2 instance.

First, create a security group.

```
resource "aws_security_group" "ssh_access" {
  name_prefix = "SSH-and-HTTP-access"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Second, EC2 instance.

```
resource "aws_instance" "web_server" {
  ami                    = "ami-0005e0cfe09cc9050" # Amazon Linux
  instance_type          = "t2.micro"
  key_name               = "my-linux-key"
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
```

Then create an elastic ip and associat it with instance.

```
resource "aws_eip" "elastic_ip" {
  instance = aws_instance.web_server.id
  tags = {
    Name = "webserver-eip"
  }
}
```

For displaying IP address of your instance in your CLI, write below code:

```
output "getIP" {
  value = aws_instance.web_server.public_ip
}
```

After adding code, run `terraform apply` and verify instance in cosole.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705094557138/ad21cef4-8b8c-46e8-91a5-052be36482e1.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705094211818/a22f8670-3135-4ad3-9bf9-03f71bcd61d8.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705094150700/8d689bcf-273b-45a7-8f04-8b4c48dd5021.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705094219169/d19048ba-1d54-45c6-bc99-926228c67192.png)

You can delete everything with `terraform destroy`

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705094435128/f8bcbcaa-fdbb-4871-a60a-c51b598689ab.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1705094472445/2fc7aa94-929a-4b8f-b5ce-57408b86e49b.png)

---

Thank you for reading!