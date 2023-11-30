terraform {
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "0.50.0"
    }
  }

  required_version = "~> 1.6.3"
}

provider "tfe" {
  token = var.tfc_api_token
}

data "tfe_organization" "helper" {
  name = var.organization_name
}

