# Region where resources will be created.
provider "aws" {
  profile = "shared"
  region  = "us-east-1"
}

# Availability zones where resources will be created.
variable "availability_zones" {
  # No spaces allowed between az names!
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# VPC CIDR Block.
variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "10.0.0.0/16"
}

# Public Route Table.
variable "public_route_table" {
  description = "Public route table created on Shared account."
  default = "0.0.0.0/0"
}

# Private Route Table.
variable "private_route_table" {
  description = "Private route table created on Shared account."
  default = "0.0.0.0/0"
}

# Mapped Public Subnets.
# "key" = "value"
variable "public_subnets" {
  description = "Map from availability zone to the number that should be used for each availability zone's subnet."
  default     = {
    "us-east-1a" = 1
    "us-east-1b" = 2
    "us-east-1c" = 3
  }
}

# Mapped Private Subnets.
# "key" = "value"
variable "private_subnets" {
  description = "Map from availability zone to the number that should be used for each availability zone's subnet."
  default     = {
    "us-east-1a" = 4
    "us-east-1b" = 5
    "us-east-1c" = 6
  }
}

# Organization Unit ARN.
variable "organization_unit" {
  description = "ARN of Organization Unit with accounts sharing resources."
  default = "arn:aws:organizations::608320206844:ou/o-45sc58wsbs/ou-1sw5-324dsgr4"
}

# This account name.
variable "acct_name" {
  description = "The name of this account. Use same as other variables."
  default = "Shared"
}

# Name of all accounts.
# The list order MUST be the same for variables accounts, dxgateways and allowed_prefixes.
variable "accounts" {
  type = map(string)
    default = {
    "Shared" = "0"
    "Prod"   = "1"
    "UAT"    = "2"
    "Dev"    = "3"
  }
}

# ASN value for Transit Gateway.
# ASN MUST be unique.
variable "tgw_asn" {
  description = "ASN used for Transit Gateway."
  default = "64515"
}

# Direct Connect Gateways. DO NOT REPEAT ASN.
# The list order MUST be the same for variables accounts, dxgateways and allowed_prefixes.
# ASN MUST be unique.
variable "dxgateways" {
  type = map(string)
  default = {
    "Shared" = "65020"
    "Prod"   = "65120"
    "UAT"    = "65220"
    "Dev"    = "65320"
  }
}

# Direct Connect Gateway Allowed Prefixes.
# The list order MUST be the same for variables accounts, dxgateways and allowed_prefixes.
# Allowed prefixes MUST be the same as the VPC CIDR block of each account.
variable "allowed_prefixes" {
    type = map(string)
    default = {
    "Shared" = "10.0.0.0/16"
    "Prod"   = "10.1.0.0/16"
    "UAT"    = "10.2.0.0/16"
    "Dev"    = "10.3.0.0/16"
  }
}