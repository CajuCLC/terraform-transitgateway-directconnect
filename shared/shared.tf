#
# Create VPC on Shared account.
#
resource "aws_vpc" "SharedEnvVPC" {
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
output "SharedEnvVPCId" {
  value = aws_vpc.SharedEnvVPC.id
}

#
# Create Internet Gateway on Shared account.
#
resource "aws_internet_gateway" "SharedEnvIGW" {
  vpc_id = aws_vpc.SharedEnvVPC.id
  tags = {
      "Name" = "${var.acct_name} IGW"
      "Environment" = "${var.acct_name}"
  }
}

#
# Create Public Route Table on Shared account.
# It uses Internet Gateway for route.
#
resource "aws_route_table" "SharedEnvPubRouteTable" {
  vpc_id = aws_vpc.SharedEnvVPC.id
  route {
      cidr_block = var.public_route_table
      gateway_id = aws_internet_gateway.SharedEnvIGW.id
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
resource "aws_subnet" "SharedEnvPubSubnet" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.SharedEnvVPC.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.SharedEnvVPC.cidr_block, 8, each.value)

  tags = {
    "Name" = replace("public_subnet_${each.key}", "-", "_")
    "Environment" = "${var.acct_name}"
  }
}

#
# Outputs Public Subnet IDs in array.
#
output "SharedEnvPubSubnetId" {
  value = {
    for pubsubnet in aws_subnet.SharedEnvPubSubnet:
    pubsubnet.id => pubsubnet.availability_zone
  }
}

#
# Associate Public Subnets to Public Route Table.
#
resource "aws_route_table_association" "SharedEnvPubSubnetRouteTableAssociation" {
  for_each = var.public_subnets

  subnet_id = aws_subnet.SharedEnvPubSubnet[each.key].id
  route_table_id = aws_route_table.SharedEnvPubRouteTable.id
}

#
# Create Transit Gateway.
# Do not create default route table and propagation.
# Enable auto accept shared attachments.
#
resource "aws_ec2_transit_gateway" "SharedEnvTGW" {
  description                     = "Transit Gateway Private Subnet"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "enable"
  amazon_side_asn = var.tgw_asn
    tags = {
    "Name" = "${var.acct_name} TGW"
    "Environment" = "${var.acct_name}"
  }
}

#
# Outputs the Transit Gateway ID.
#
output "SharedEnvTGWId" {
  value = aws_ec2_transit_gateway.SharedEnvTGW.id
}

#
# Create Transit Gateway VPC Attachment.
#
resource "aws_ec2_transit_gateway_vpc_attachment" "SharedEnvTGWAttchment" {
  subnet_ids = [
    for prisubnets in aws_subnet.SharedEnvPrivateSubnet:
    prisubnets.id
  ]
  transit_gateway_id = aws_ec2_transit_gateway.SharedEnvTGW.id
  vpc_id             = aws_vpc.SharedEnvVPC.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    "Name" = "${var.acct_name} TGW Attachment"
    "Environment" = "${var.acct_name}"
  }
  depends_on         = [aws_ec2_transit_gateway.SharedEnvTGW]
}

#
# Create Transit Gateway Route Tables.
# Loop variable accounts to create one route table per environment.
#
resource "aws_ec2_transit_gateway_route_table" "SharedEnvTGWRouteTable" {
  for_each = var.accounts
  transit_gateway_id = aws_ec2_transit_gateway.SharedEnvTGW.id
  tags               = {
    "Name"             = "${each.key}"
    "Environment" = "${each.key}"
  }
  depends_on = [aws_ec2_transit_gateway.SharedEnvTGW]
}

#
# Get all Transit Gateway Route Table IDs.
#
data "aws_ec2_transit_gateway_route_table" "TGWRouteTableId" {
  for_each = var.accounts
  id = aws_ec2_transit_gateway_route_table.SharedEnvTGWRouteTable[each.key].id
  depends_on = [aws_ec2_transit_gateway_route_table.SharedEnvTGWRouteTable]
}

#
# Create Private Route Table.
# It uses Transint Gateway for route.
#
resource "aws_route_table" "SharedEnvPrivateRouteTable" {
  vpc_id = aws_vpc.SharedEnvVPC.id
  route {
      cidr_block = var.private_route_table
      transit_gateway_id = aws_ec2_transit_gateway.SharedEnvTGW.id
  }
  tags = {
      "Name" = "${var.acct_name} Private Subnet Route Table"
      "Environment" = "${var.acct_name}"
  }
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.SharedEnvTGWAttchment]
}

#
# Create Private Subnets.
# Variable private_subnets.
# availability_zone will loop the variable key for the AZs.
# cidr_block will adds 8 bits to the VPC. Each value is the range.
# If VPC is 10.0.0.0/16, subnets will be 10.x.0.0/24.
#
resource "aws_subnet" "SharedEnvPrivateSubnet" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.SharedEnvVPC.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.SharedEnvVPC.cidr_block, 8, each.value)

  tags = {
    "Name" = replace("private_subnet_${each.key}", "-", "_")
    "Environment" = "${var.acct_name}"
  }
}

#
# Outputs all Private Subnets IDs.
#
output "SharedEnvPrivateSubnetId" {
  value = {
    for privsubnet in aws_subnet.SharedEnvPrivateSubnet :
    privsubnet.availability_zone => privsubnet.id
  }
}

#
# Associate Private Subnets to private Route Table.
#
resource "aws_route_table_association" "SharedEnvPrivateSubnetRouteTableAssociation" {
  for_each = var.private_subnets

  subnet_id = aws_subnet.SharedEnvPrivateSubnet[each.key].id
  route_table_id = aws_route_table.SharedEnvPrivateRouteTable.id
  depends_on = [aws_route_table.SharedEnvPrivateRouteTable,aws_subnet.SharedEnvPrivateSubnet]
}

#
# Create Resource Access Manager (RAM).
#
resource "aws_ram_resource_share" "SharedEnvRAM" {
  name                      = "SharedAccountResourceShare"
  allow_external_principals = true

  tags = {
    "Environment" = "${var.acct_name}"
  }
  depends_on =[aws_ec2_transit_gateway.SharedEnvTGW]
}

#
# Associated Transit Gateway with Resource Access Manager.
#
resource "aws_ram_resource_association" "SharedEnvRAMTGWAssociation" {
  resource_arn       = aws_ec2_transit_gateway.SharedEnvTGW.arn
  resource_share_arn = aws_ram_resource_share.SharedEnvRAM.arn
}

#
# Get Resource Access Manager ID.
#
output "SharedEnvRAMTGWAssociationId" {
  value = aws_ram_resource_association.SharedEnvRAMTGWAssociation.id
}

#
# Share Transit Gateway with Organization Unit using Resource Access Manager.
#
resource "aws_ram_principal_association" "RamTgwOu" {
  principal          = var.organization_unit
  resource_share_arn = aws_ram_resource_share.SharedEnvRAM.arn
  depends_on = [aws_ram_resource_association.SharedEnvRAMTGWAssociation]
}

#
# Get Resource Access Manager SHARE ID.
#
output "RamTgwOuId" {
  value = aws_ram_principal_association.RamTgwOu.resource_share_arn
}

#
# Create Direct Connect Gateway.
# Loops variable dxgateways for the list of name and ASN.
#
resource "aws_dx_gateway" "CreateDxGw" {
  for_each = var.dxgateways
  name            = each.key
  amazon_side_asn = each.value
}

#
# Get ID of each Direct Connect Gateway.
#
data "aws_dx_gateway" "GetDxGwId" {
  for_each = var.dxgateways
  name            = each.key
  depends_on = [aws_dx_gateway.CreateDxGw]
}

#
# Associate Direct Connect Gateways with Transit Gateway.
# Loops variable allowed_prefixes to match environment.
# Prefixes should match each environment VPC CIDR Block.
# A Transit Gateway Attachment will be created for each environment.
#
resource "aws_dx_gateway_association" "DxGwTGwAssociation" {
  for_each = var.allowed_prefixes
  dx_gateway_id         = data.aws_dx_gateway.GetDxGwId[each.key].id
  associated_gateway_id = aws_ec2_transit_gateway.SharedEnvTGW.id
  allowed_prefixes = [each.value]

  depends_on = [aws_dx_gateway.CreateDxGw]
}

#
# Get list of Direct Connect Gateway Attachment IDs.
#
data "aws_ec2_transit_gateway_dx_gateway_attachment" "GetDxGwTGwAttachment" {
  for_each = var.accounts
  transit_gateway_id = aws_ec2_transit_gateway.SharedEnvTGW.id
  dx_gateway_id         = data.aws_dx_gateway.GetDxGwId[each.key].id
  depends_on = [aws_dx_gateway_association.DxGwTGwAssociation]
}

#
# Associate Direct Connect Gateway with Transit Gateway Route Table.
#
resource "aws_ec2_transit_gateway_route_table_association" "DxGwTGwRouteTableAssociation" {
  for_each = var.accounts
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_dx_gateway_attachment.GetDxGwTGwAttachment[each.key].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.TGWRouteTableId[each.key].id
  depends_on = [aws_ec2_transit_gateway_route_table.SharedEnvTGWRouteTable, aws_dx_gateway_association.DxGwTGwAssociation]
}

#
# Propagate Direct Connect Gateway with Transit Gateway Route Table.
#
resource "aws_ec2_transit_gateway_route_table_propagation" "DxGwTGwRouteTablePropagation" {
  for_each = var.accounts
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_dx_gateway_attachment.GetDxGwTGwAttachment[each.key].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.TGWRouteTableId[each.key].id
  depends_on = [aws_ec2_transit_gateway_route_table.SharedEnvTGWRouteTable, aws_dx_gateway_association.DxGwTGwAssociation]
}