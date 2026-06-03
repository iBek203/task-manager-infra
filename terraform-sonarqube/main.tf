data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "sonarqube" {
  cidr_block           = "10.10.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "task-manager-sonarqube-vpc" }
}

resource "aws_internet_gateway" "sonarqube" {
  vpc_id = aws_vpc.sonarqube.id
}

resource "aws_subnet" "sonarqube" {
  vpc_id                  = aws_vpc.sonarqube.id
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "task-manager-sonarqube-subnet" }
}

resource "aws_route_table" "sonarqube" {
  vpc_id = aws_vpc.sonarqube.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sonarqube.id
  }
}

resource "aws_route_table_association" "sonarqube" {
  subnet_id      = aws_subnet.sonarqube.id
  route_table_id = aws_route_table.sonarqube.id
}
