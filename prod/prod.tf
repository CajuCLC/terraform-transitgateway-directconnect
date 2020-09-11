#
# Create VPC on Dev account.
#
resource "aws_vpc" "ProdEnvVPC" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
      "Name" = "${var.acct_name} VPC"
      "Environment" = "${var.acct_name}"
  }
}

#
# Output VPC ID.
#
output "ProdEnvVPCId" {
  value = aws_vpc.ProdEnvVPC.id
}

#
# Create Internet Gateway on Dev account.
#
resource "aws_internet_gateway" "ProdEnvIGW" {
  vpc_id = aws_vpc.ProdEnvVPC.id
  tags = {
      "Name" = "${var.acct_name} IGW"
      "Environment" = "${var.acct_name}"
  }
}

#
# Create Public Route Table on Shared account.
# It uses Internet Gateway for route.
#
resource "aws_route_table" "ProdEnvPubRouteTable" {
  vpc_id = aws_vpc.ProdEnvVPC.id
  route {
      cidr_block = var.public_route_table
      gateway_id = aws_internet_gateway.ProdEnvIGW.id
  }
  tags = {
      "Name" = "${var.acct_name} Public Subnet Route Table"
      "Environment" = "${var.acct_name}"
  }
}

#
# Create Public Subnets.
# availability_zone will loop the variable key for the AZs.
# cidr_block will adds 8 bits to the VPC. Each value is the range.
# If VPC is 10.0.0.0/16, subnets will be 10.x.0.0/24.
#
resource "aws_subnet" "ProdEnvPubSubnet" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.ProdEnvVPC.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.ProdEnvVPC.cidr_block, 8, each.value)

  tags = {
    "Name" = replace("public_subnet_${each.key}", "-", "_")
    "Environment" = "${var.acct_name}"
  }
}

#
# Outputs Public Subnet IDs in array.
#
output "ProdEnvPubSubnetId" {
  value = {
    for psubnet in aws_subnet.ProdEnvPubSubnet:
    psubnet.id => psubnet.availability_zone
  }
}

#
# Associate Public Subnets to Public Route Table.
#
resource "aws_route_table_association" "ProdEnvPubSubnetRouteTableAssociation" {
  for_each = var.public_subnets

  subnet_id = aws_subnet.ProdEnvPubSubnet[each.key].id
  route_table_id = aws_route_table.ProdEnvPubRouteTable.id
}

#
# Create Transit Gateway VPC Attachment.
# Attached to Shared Account Transit Gateway.
#
resource "aws_ec2_transit_gateway_vpc_attachment" "ProdEnvTGWAttchment" {
  subnet_ids = [
    for prinet in aws_subnet.ProdEnvPrivateSubnet:
    prinet.id
  ]
  transit_gateway_id = var.SharedEnvTGWId
  vpc_id             = aws_vpc.ProdEnvVPC.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    "Name" = "${var.acct_name} TGW Attachment"
    "Environment" = "${var.acct_name}"
  }
  depends_on         = [
    var.SharedEnvTGWId,
    var.SharedEnvRAMTGWAssociationId,
    var.RamTgwOuId
  ]
}

#
# Create Private Route Table.
# It uses Transint Gateway for route.
#
resource "aws_route_table" "ProdEnvPrivateRouteTable" {
  vpc_id = aws_vpc.ProdEnvVPC.id
  route {
      cidr_block = var.private_route_table
      transit_gateway_id = var.SharedEnvTGWId
  }
  tags = {
      "Name" = "${var.acct_name} Private Subnet Route Table"
      "Environment" = "${var.acct_name}"
  }
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.ProdEnvTGWAttchment]
}

#
# Create Private Subnets.
# Variable private_subnets.
# availability_zone will loop the variable key for the AZs.
# cidr_block will adds 8 bits to the VPC. Each value is the range.
# If VPC is 10.0.0.0/16, subnets will be 10.x.0.0/24.
#
resource "aws_subnet" "ProdEnvPrivateSubnet" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.ProdEnvVPC.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.ProdEnvVPC.cidr_block, 8, each.value)

  tags = {
    "Name" = replace("private_subnet_${each.key}", "-", "_")
    "Environment" = "${var.acct_name}"
  }
}

output "ProdEnvPrivateSubnetId" {
  value = {
    for privsubnets in aws_subnet.ProdEnvPrivateSubnet :
    privsubnets.availability_zone => privsubnets.id
  }
}

#
# Associate Private Subnets to private Route Table.
#
resource "aws_route_table_association" "ProdEnvPrivateSubnetRouteTableAssociation" {
  for_each = var.private_subnets

  subnet_id = aws_subnet.ProdEnvPrivateSubnet[each.key].id
  route_table_id = aws_route_table.ProdEnvPrivateRouteTable.id
  depends_on = [aws_route_table.ProdEnvPrivateRouteTable,aws_subnet.ProdEnvPrivateSubnet]
}