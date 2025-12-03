locals {
  env = var.environment

  config = {
    dev = {
      master_vm_size = "Standard_D8s_v3"
      worker_vm_size = "Standard_D4s_v3"
      infra_vm_size  = "Standard_D2s_v3"

      worker_count          = 2
      worker_count_per_pool = 1
      infra_count           = 2

      master_disk_gb = 128
      worker_disk_gb = 128
      infra_disk_gb  = 128

      api_visibility     = "Public"
      ingress_visibility = "Public"

      fips_enabled       = false
      encryption_enabled = false
    }

    stg = {
      master_vm_size = "Standard_D8s_v3"
      worker_vm_size = "Standard_D4s_v3"
      infra_vm_size  = "Standard_D4s_v3"

      worker_count          = 3
      worker_count_per_pool = 2
      infra_count           = 3

      master_disk_gb = 128
      worker_disk_gb = 128
      infra_disk_gb  = 128

      api_visibility     = "Private"
      ingress_visibility = "Private"

      fips_enabled       = false
      encryption_enabled = false
    }

    prod = {
      master_vm_size = "Standard_D16s_v3"
      worker_vm_size = "Standard_D8s_v3"
      infra_vm_size  = "Standard_D8s_v3"

      worker_count          = 3
      worker_count_per_pool = 3
      infra_count           = 3

      master_disk_gb = 256
      worker_disk_gb = 256
      infra_disk_gb  = 256

      api_visibility     = "Private"
      ingress_visibility = "Private"

      fips_enabled       = true
      encryption_enabled = true
    }
  }

  current = local.config[local.env]

  control_subnet = {
    name   = "snet-control-${local.env}"
    prefix = var.control_subnet_prefix
  }

  worker_subnets = {
    for idx, prefix in var.worker_subnet_prefixes :
    "worker-${idx + 1}" => {
      name   = "snet-worker-${idx + 1}-${local.env}"
      prefix = prefix
    }
  }

  tags = merge(var.tags, {
    Environment = local.env
    ManagedBy   = "Terraform"
  })
}
