resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block[terraform.workspace]
  instance_tenancy = "default"

  tags = {
    Name        = "Main VPC"
    Iac = true
    Environment = "${terraform.workspace}"
  }
}

resource "aws_subnet" "subnets" {
  count                   = var.public_subnet_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block[terraform.workspace], 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-${count.index + 1}"
    Iac = true
    Environment = "${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    IaC = true
    Environment = "${terraform.workspace}"
  }
}