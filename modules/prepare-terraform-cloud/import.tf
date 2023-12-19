import {
  to = tfe_organization.main
  id = var.organization_name
}

import {
  to = tfe_workspace.remote_operations
  id = "${var.organization_name}/${var.remote_operations_workspace}"
}
