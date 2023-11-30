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

resource "tfe_organization" "org" {
  name  = var.organization_name
  email = var.organization_email
}

resource "tfe_project" "project" {
  organization = tfe_organization.org.name
  name         = var.project_name
}

resource "tfe_workspace" "test" {
  name           = var.workspace_name
  organization   = tfe_organization.org.name
  project_id     = tfe_project.project.id
}
