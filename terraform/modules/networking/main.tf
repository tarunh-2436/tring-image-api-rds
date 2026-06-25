###############################################
# VPC
###############################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

###############################################
# Internet Gateway
###############################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

###############################################
# Elastic IP
###############################################

resource "aws_eip" "this" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-nat-eip"
    }
  )
}

###############################################
# Public Subnets
###############################################

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-${count.index + 1}"
    }
  )
}

###############################################
# Private Subnets
###############################################

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  cidr_block = var.private_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-private-${count.index + 1}"
    }
  )
}

###############################################
# NAT Gateway
###############################################

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id

  subnet_id = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-nat"
    }
  )
}

###############################################
# Public Route Table
###############################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-rt"
    }
  )
}

###############################################
# Private Route Tables
###############################################

resource "aws_route_table" "private" {

  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-private-${count.index + 1}-rt"
    }
  )
}

###############################################
# Public Route Table Associations
###############################################

resource "aws_route_table_association" "public" {

  count = length(var.public_subnet_cidrs)

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

###############################################
# Private Route Table Associations
###############################################

resource "aws_route_table_association" "private" {

  count = length(var.private_subnet_cidrs)

  subnet_id = aws_subnet.private[count.index].id

  route_table_id = aws_route_table.private[count.index].id
}