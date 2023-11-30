import {
  to = tfe_organization.main
  id = var.organization_name
}

import {
  to = tfe_workflow.remote_operations
  id = "${var.organization_name}/${var.remote_operations_workflow}"
}
