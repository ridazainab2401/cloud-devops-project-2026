terraform {
  backend "s3" {
    bucket       = "devops-lab-2026-state-bucket-rida" 
    key          = "global/s3/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true   
  }
}
provider "aws" {
  region = var.aws_region
}


#----- STATE BACKEND RESOURCES (S3)-----

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-state-bucket-rida" 
  
 
  lifecycle {
    prevent_destroy = true
  }
}


# ----- NETWORKING (VPC, Subnets, Gateways)------

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  tags = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  tags = { Name = "${var.project_name}-private-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "${var.project_name}-igw" }
}

# --------NAT Gateway requires an Elastic IP--------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = { Name = "${var.project_name}-nat" }
}

#--------- Route table for Public Subnet --------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#-------- Route table for Private Subnet (Goes to NAT Gateway)-------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}