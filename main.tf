# Includes Terraform required version.
# Includes AWS version required.
terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      version = ">= 3.3.0"
      source = "hashicorp/aws"
    }
  }
}

module "shared" {
  source            = "./shared"
}

module "prod" {
  source                          = "./prod"
  SharedEnvTGWId                  = module.shared.SharedEnvTGWId
  SharedEnvRAMTGWAssociationId    = module.shared.SharedEnvRAMTGWAssociationId
  RamTgwOuId = module.shared.RamTgwOuId
}

module "uat" {
  source                          = "./uat"
  SharedEnvTGWId                  = module.shared.SharedEnvTGWId
  SharedEnvRAMTGWAssociationId    = module.shared.SharedEnvRAMTGWAssociationId
  RamTgwOuId = module.shared.RamTgwOuId
}

module "dev" {
  source                          = "./dev"
  SharedEnvTGWId                  = module.shared.SharedEnvTGWId
  SharedEnvRAMTGWAssociationId    = module.shared.SharedEnvRAMTGWAssociationId
  RamTgwOuId = module.shared.RamTgwOuId
}