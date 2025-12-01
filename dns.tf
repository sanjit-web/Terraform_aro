# DNS Zone using AVM
module "dns_zone" {
  source  = "Azure/avm-res-network-dnszone/azurerm"
  version = "~> 0.2"

  count = var.create_dns_zone ? 1 : 0

  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# A Record for Ingress
resource "azurerm_dns_a_record" "ingress" {
  count = var.create_dns_zone && var.ingress_ip != "" ? 1 : 0

  name                = "*.apps"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.ingress_ip]

  depends_on = [module.dns_zone]

  tags = var.tags
}
