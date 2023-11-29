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

resource "tfe_organization" "test" {
  name  = var.tfc_organization_name
  email = var.tfc_organization_email
}

