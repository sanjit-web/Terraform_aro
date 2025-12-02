# Resource Group using AVM
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.1"

  name     = local.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Service Principal Role Assignment
resource "azurerm_role_assignment" "aro_sp_contributor" {
  scope                = module.resource_group.resource_id
  role_definition_name = "Contributor"
  principal_id         = var.sp_object_id

  depends_on = [module.resource_group]
}

# User Assigned Identity for ARO
resource "azurerm_user_assigned_identity" "aro" {
  name                = "id-aro-${local.env_prefix}-${var.location}"
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = local.common_tags
}

# Role Assignment for User Assigned Identity
resource "azurerm_role_assignment" "aro_identity_contributor" {
  scope                = module.resource_group.resource_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aro.principal_id

  depends_on = [azurerm_user_assigned_identity.aro]
}
