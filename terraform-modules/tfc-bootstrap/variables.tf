variable "tfc_api_token" {
  type = string
  description = "TFC Personal Access Token to use for bootstrapping"
}

variable "organization_name" {
  type = string
  description = "Name of the organization"
}

variable "organization_email" {
  type = string
  description = "Email of the organization"
}

variable "project_name" {
  type = string
  default = "remote-operations"
  description = "Project name for remote-operation-related tasks"
}

variable "workspace_name" {
  type = string
  default = "remote-operations"
  description = "Workspace name for remote-operation-related tasks"
}
