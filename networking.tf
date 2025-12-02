# Virtual Network using AVM
module "vnet_new" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.1"

  name                = local.vnet_name
  resource_group_name = module.resource_group.name
  location            = var.location

  address_space = [local.network.vnet_address_space]

  subnets = merge(
    # Control Plane Subnet
    {
      (local.network.control_subnet.name) = {
        address_prefixes = [local.network.control_subnet.address_prefix]

        service_endpoints = [
          "Microsoft.ContainerRegistry",
          "Microsoft.Storage"
        ]

        delegation = [{
          name = "aro-control-delegation"
          service_delegation = {
            name = "Microsoft.RedHatOpenShift/redhatopenshift"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
            ]
          }
        }]
      }
    },

    # Worker Subnets
    {
      for name, config in local.network.worker_subnets :
      config.name => {
        address_prefixes = [config.address_prefix]

        service_endpoints = [
          "Microsoft.ContainerRegistry",
          "Microsoft.Storage"
        ]

        delegation = [{
          name = "aro-worker-delegation"
          service_delegation = {
            name = "Microsoft.RedHatOpenShift/redhatopenshift"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
            ]
          }
        }]
      }
    }
  )

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# Network Security Group for Control Subnet
resource "azurerm_network_security_group" "control" {
  name                = "nsg-aro-control-${local.env_prefix}"
  location            = var.location
  resource_group_name = module.resource_group.name

  security_rule {
    name                       = "AllowAROControlPlane"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6443", "22623"]
    source_address_prefix      = "AzureCloud"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Network Security Group for Worker Subnets
resource "azurerm_network_security_group" "worker" {
  for_each = local.network.worker_subnets

  name                = "nsg-aro-${each.key}-${local.env_prefix}"
  location            = var.location
  resource_group_name = module.resource_group.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# NSG Association - Control Subnet
resource "azurerm_subnet_network_security_group_association" "control" {
  subnet_id                 = module.vnet_new.subnets[local.network.control_subnet.name].resource_id
  network_security_group_id = azurerm_network_security_group.control.id

  depends_on = [module.vnet_new]
}

# NSG Association - Worker Subnets
resource "azurerm_subnet_network_security_group_association" "worker" {
  for_each = local.network.worker_subnets

  subnet_id                 = module.vnet_new.subnets[each.value.name].resource_id
  network_security_group_id = azurerm_network_security_group.worker[each.key].id

  depends_on = [module.vnet_new]
}
