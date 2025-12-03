output "vnet_id" {
  value = module.vnet.resource_id
}

output "control_subnet_id" {
  value = module.vnet.subnets[local.control_subnet.name].resource_id
}

output "worker_subnet_ids" {
  value = [for k, v in module.vnet.subnets : v.resource_id if startswith(k, "worker-")]
}

output "aro_id" {
  value = azurerm_redhat_openshift_cluster.main.id
}

output "aro_console_url" {
  value = azurerm_redhat_openshift_cluster.main.console_url
}
