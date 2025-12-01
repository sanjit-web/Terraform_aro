# Virtual Network and Subnets
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.2"

  name     = var.vnet_name
  location = var.location

  # Resource group as parent resource
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  address_space = [var.vnet_address_space]

  subnets = merge(
    {
      control = {
        name             = var.control_subnet_name
        address_prefixes = [var.control_subnet_prefix]
      }
    },
    {
      for idx, prefix in var.worker_subnet_prefixes :
      "worker-${idx + 1}" => {
        name             = "${var.worker_subnet_name_prefix}-${idx + 1}"
        address_prefixes = [prefix]
      }
    }
  )

  tags = var.tags
}
