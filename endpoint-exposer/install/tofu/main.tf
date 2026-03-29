################################################################################
# Service Definition
# Registers the service specification and action specs in nullplatform.
################################################################################

module "service_definition" {
  source = "../../../../tofu-modules/nullplatform/service_definition"

  nrn        = var.nrn
  np_api_key = var.np_api_key

  # Spec templates are fetched from the nullplatform/services GitHub repository
  git_repo         = var.git_repo
  git_ref          = var.git_branch
  git_service_path = var.git_service_path
  use_tpl_files    = true

  git_password = var.github_token

  service_name        = var.service_name
  service_description = var.service_description
}

################################################################################
# Service Definition Agent Association
# Creates the notification channel that connects nullplatform events to the agent.
################################################################################

module "service_definition_agent_association" {
  source = "../../../../tofu-modules/nullplatform/service_definition_agent_association"

  nrn     = var.nrn
  api_key = var.np_api_key

  service_specification_id   = module.service_definition.service_specification_id
  service_specification_slug = module.service_definition.service_specification_slug

  tags_selectors = var.tags_selectors

  agent_command = {
    type = "exec"
    data = {
      cmdline = "${var.repo_path}/entrypoint"
    }
  }

  service_path           = var.repo_path
  workflow_override_path = var.overrides_enabled ? var.overrides_repo_path : null
}
