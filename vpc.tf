resource "aws_vpc" "oceanblue" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    "Name" = "oceanblue-vpc"
  }
}

resource "aws_subnet" "oceanblue_subnet_1a" {
  vpc_id            = aws_vpc.oceanblue.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "oceanblue-subnet-1a"
  }
}

resource "aws_subnet" "oceanblue_subnet_1b" {
  vpc_id            = aws_vpc.oceanblue.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "oceanblue-subnet-1b"
  }
}

resource "aws_subnet" "oceanblue_subnet_1c" {
  vpc_id            = aws_vpc.oceanblue.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "oceanblue-subnet-1c"
  }
}


