module "rg_aro" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.1"

  name     = "${var.resource_group_name}-aro"
  location = var.location
  tags     = local.tags
}

resource "azurerm_redhat_openshift_cluster" "main" {
  depends_on = [module.vnet]

  name                = var.cluster_name
  location            = var.location
  resource_group_name = module.rg_aro.name

  cluster_profile {
    domain                      = var.domain
    version                     = var.openshift_version
    pull_secret                 = file(var.pull_secret_path)
    fips_enabled                = local.current.fips_enabled
    managed_resource_group_name = "${module.rg_aro.name}-managed"
  }

  main_profile {
    vm_size                    = local.current.master_vm_size
    subnet_id                  = [for k, v in module.vnet.subnets : v.resource_id if k == local.control_subnet.name][0]
    encryption_at_host_enabled = local.current.encryption_enabled
  }

  worker_profile {
    vm_size                    = local.current.worker_vm_size
    disk_size_gb               = local.current.worker_disk_gb
    node_count                 = local.current.worker_count
    subnet_id                  = [for k, v in module.vnet.subnets : v.resource_id if startswith(k, "worker-")][0]
    encryption_at_host_enabled = local.current.encryption_enabled
  }

  service_principal {
    client_id     = var.sp_client_id
    client_secret = var.sp_client_secret
  }

  api_server_profile {
    visibility = local.current.api_visibility
  }

  ingress_profile {
    visibility = local.current.ingress_visibility
  }

  network_profile {
    pod_cidr                                     = var.pod_cidr
    service_cidr                                 = var.service_cidr
    outbound_type                                = var.outbound_type
    preconfigured_network_security_group_enabled = true
  }

  tags = local.tags
}
