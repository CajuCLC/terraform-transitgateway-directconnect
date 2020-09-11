# Region where resources will be created.
provider "aws" {
  profile = "prod"
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
  default     = "10.1.0.0/16"
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

# This account name.
variable "acct_name" {
  description = "The name of this account. Use same as other variables."
  default = "Prod"
}

# Variables from Shared account.
variable "SharedEnvTGWId" {}
variable "SharedEnvRAMTGWAssociationId" {}
variable "RamTgwOuId" {}