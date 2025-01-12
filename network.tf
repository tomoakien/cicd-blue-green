#構成
#private-subnet*2,public-subnet*2
#internetgateway,natgateway*2
#VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

#----------------------------------------------------------------
#subnet
resource "aws_subnet" "pub_1" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "pub_2" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "pri_1" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.3.0/24"
}

resource "aws_subnet" "pri_2" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.4.0/24"
}

#----------------------------------------------------------------
#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#----------------------------------------------------------------
#EIP
resource "aws_eip" "nat1" {
}

resource "aws_eip" "nat2" {
}

#----------------------------------------------------------------
#natgateway
resource "aws_nat_gateway" "ngw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.pub_1.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.pub_2.id
  depends_on    = [aws_internet_gateway.igw]
}

#----------------------------------------------------------------
#aws route table public
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
}

#internet gatewayへのルート追加
resource "aws_route" "to_igw" {
  route_table_id         = aws_route_table.pub_rt.id
  destination_cidr_block = local.any_cidr
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "pub_rt1" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt2" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.pub_rt.id
}

#----------------------------------------------------------------
#aws route table private
resource "aws_route_table" "pri_rt1" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "pri_rt2" {
  vpc_id = aws_vpc.vpc.id
}

#nat1へのルート追加
resource "aws_route" "to_nat1" {
  route_table_id         = aws_route_table.pri_rt1.id
  destination_cidr_block = local.any_cidr
  gateway_id             = aws_nat_gateway.ngw1.id
}

#nat2へのルート追加
resource "aws_route" "to_nat2" {
  route_table_id         = aws_route_table.pri_rt2.id
  destination_cidr_block = local.any_cidr
  gateway_id             = aws_nat_gateway.ngw2.id
}

#
resource "aws_route_table_association" "pri_rt1" {
  subnet_id      = aws_subnet.pri_1.id
  route_table_id = aws_route_table.pri_rt1.id
}

resource "aws_route_table_association" "pri_rt2" {
  subnet_id      = aws_subnet.pri_2.id
  route_table_id = aws_route_table.pri_rt2.id
}
