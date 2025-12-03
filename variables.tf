variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be dev, stg, or prod."
  }
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vnet_name" {
  type    = string
  default = "aro-vnet"
}

variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "control_subnet_prefix" {
  type = string
}

variable "worker_subnet_prefixes" {
  description = "List of worker subnet CIDRs"
  type        = list(string)
}

variable "cluster_name" {
  description = "ARO cluster name"
  type        = string
}

variable "domain" {
  type    = string
  default = ""
}

variable "openshift_version" {
  type    = string
  default = "4.12.25"
}

variable "pull_secret_path" {
  type = string
}

variable "master_vm_size" {
  type    = string
  default = "Standard_D8s_v3"
}

variable "worker_vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "worker_disk_size_gb" {
  type    = number
  default = 128
}

variable "worker_node_count" {
  type    = number
  default = 3
}

variable "worker_node_count_per_pool" {
  type    = number
  default = 2
}

variable "sp_client_id" {
  type      = string
  sensitive = true
}

variable "sp_client_secret" {
  type      = string
  sensitive = true
}

variable "sp_object_id" {
  type      = string
  sensitive = true
}

variable "outbound_type" {
  type    = string
  default = "Loadbalancer"
  validation {
    condition     = contains(["Loadbalancer", "UserDefinedRouting"], var.outbound_type)
    error_message = "Outbound type must be either 'Loadbalancer' or 'UserDefinedRouting'."
  }
}

variable "api_visibility" {
  type    = string
  default = "Public"
}

variable "ingress_visibility" {
  type    = string
  default = "Public"
}

variable "infra_vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "infra_disk_size_gb" {
  type    = number
  default = 128
}

variable "infra_node_count" {
  description = "Number of infra nodes"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}


variable "control_subnet_name" {
  type    = string
  default = "aro-control-subnet"
}

variable "worker_subnet_name_prefix" {
  type    = string
  default = "aro-worker-subnet"
}

variable "pod_cidr" {
  type    = string
  default = "10.128.0.0/14"
}

variable "service_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "create_storage" {
  type    = bool
  default = false
}

variable "storage_account_name" {
  type    = string
  default = ""
}

variable "account_tier" {
  type    = string
  default = "Standard"
}

variable "replication_type" {
  type    = string
  default = "LRS"
}

variable "account_kind" {
  type    = string
  default = "StorageV2"
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "enable_change_feed" {
  type    = bool
  default = false
}

variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "public_network_access" {
  type    = bool
  default = true
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = ""
}

variable "create_dns_zone" {
  type    = bool
  default = false
}

variable "dns_zone_name" {
  type    = string
  default = ""
}

variable "ingress_ip" {
  type    = string
  default = ""
}

variable "create_frontdoor" {
  type    = bool
  default = false
}

variable "frontdoor_name" {
  type    = string
  default = ""
}

variable "backend_address" {
  type    = string
  default = ""
}

variable "backend_host_header" {
  type    = string
  default = ""
}

variable "domain_resource_group_name" {
  type    = string
  default = ""
}
