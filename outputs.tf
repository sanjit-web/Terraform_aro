# Root outputs

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.vnet.resource_id
}

output "control_subnet_id" {
  description = "Control plane subnet ID"
  value       = [for k, v in module.vnet.subnets : v.resource_id if k == "control"][0]
}

output "worker_subnet_ids" {
  description = "Worker subnet IDs"
  value       = [for k, v in module.vnet.subnets : v.resource_id if startswith(k, "worker-")]
}

output "aro_id" {
  description = "ARO cluster ID"
  value       = azurerm_redhat_openshift_cluster.main.id
}

output "aro_console_url" {
  description = "ARO console URL"
  value       = azurerm_redhat_openshift_cluster.main.console_url
}
