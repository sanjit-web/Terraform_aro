module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.1"

  name             = var.vnet_name
  parent_id        = module.resource_group.resource_id
  location         = var.location
  enable_telemetry = true

  address_space = [var.vnet_address_space]

  subnets = merge(
    {
      (local.control_subnet.name) = {
        address_prefixes = [local.control_subnet.prefix]

        service_endpoints = [
          "Microsoft.ContainerRegistry",
          "Microsoft.Storage"
        ]

        delegations = [{
          name = "aro-control"
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
    {
      for name, config in local.worker_subnets :
      config.name => {
        address_prefixes = [config.prefix]

        service_endpoints = [
          "Microsoft.ContainerRegistry",
          "Microsoft.Storage"
        ]

        delegations = [{
          name = "aro-worker"
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

  tags = local.tags

  depends_on = [module.resource_group]
}

resource "azurerm_network_security_group" "control" {
  name                = "nsg-control-${local.env}"
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

  tags = local.tags
}

resource "azurerm_network_security_group" "worker" {
  for_each = local.worker_subnets

  name                = "nsg-${each.key}-${local.env}"
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

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "control" {
  subnet_id                 = module.vnet.subnets[local.control_subnet.name].resource_id
  network_security_group_id = azurerm_network_security_group.control.id

  depends_on = [module.vnet]
}

resource "azurerm_subnet_network_security_group_association" "worker" {
  for_each = local.worker_subnets

  subnet_id                 = module.vnet.subnets[each.value.name].resource_id
  network_security_group_id = azurerm_network_security_group.worker[each.key].id

  depends_on = [module.vnet]
}
