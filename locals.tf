locals {
  # Environment-specific naming
  environment_prefix = {
    dev  = "dev"
    stg  = "stg"
    prod = "prod"
  }

  # Environment-specific settings
  environment_config = {
    dev = {
      vm_size_master = "Standard_D8s_v3"
      vm_size_worker = "Standard_D4s_v3"
      vm_size_infra  = "Standard_D2s_v3"

      worker_count_initial  = 2
      worker_count_per_pool = 1
      infra_count           = 2

      disk_size_master = 128
      disk_size_worker = 128
      disk_size_infra  = 128

      api_visibility     = "Public"
      ingress_visibility = "Public"

      enable_monitoring = false
      enable_backup     = false
    }

    stg = {
      vm_size_master = "Standard_D8s_v3"
      vm_size_worker = "Standard_D4s_v3"
      vm_size_infra  = "Standard_D4s_v3"

      worker_count_initial  = 3
      worker_count_per_pool = 2
      infra_count           = 3

      disk_size_master = 128
      disk_size_worker = 128
      disk_size_infra  = 128

      api_visibility     = "Private"
      ingress_visibility = "Private"

      enable_monitoring = true
      enable_backup     = false
    }

    prod = {
      vm_size_master = "Standard_D16s_v3"
      vm_size_worker = "Standard_D8s_v3"
      vm_size_infra  = "Standard_D8s_v3"

      worker_count_initial  = 3
      worker_count_per_pool = 3
      infra_count           = 3

      disk_size_master = 256
      disk_size_worker = 256
      disk_size_infra  = 256

      api_visibility     = "Private"
      ingress_visibility = "Private"

      enable_monitoring = true
      enable_backup     = true
    }
  }

  # Current environment settings
  env_config = local.environment_config[var.environment]
  env_prefix = local.environment_prefix[var.environment]

  # Naming convention
  resource_group_name = "rg-aro-${local.env_prefix}-${var.location}"
  cluster_name        = "aro-${local.env_prefix}-${var.location}"
  vnet_name           = "vnet-aro-${local.env_prefix}-${var.location}"

  # Network configuration
  network = {
    vnet_address_space = var.vnet_address_space
    control_subnet = {
      name           = "snet-aro-control-${local.env_prefix}"
      address_prefix = var.control_subnet_prefix
    }
    worker_subnets = {
      for idx, prefix in var.worker_subnet_prefixes :
      "worker-${idx + 1}" => {
        name           = "snet-aro-worker-${idx + 1}-${local.env_prefix}"
        address_prefix = prefix
      }
    }
  }

  # Tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "ARO-Infrastructure"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    }
  )
}
