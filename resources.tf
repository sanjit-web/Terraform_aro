module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.1"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_role_assignment" "sp" {
  scope                = module.resource_group.resource_id
  role_definition_name = "Contributor"
  principal_id         = var.sp_object_id
}
