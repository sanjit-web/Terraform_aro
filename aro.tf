# Azure Red Hat OpenShift Cluster
resource "azurerm_redhat_openshift_cluster" "main" {
  depends_on = [module.vnet]

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name

  cluster_profile {
    domain      = var.domain
    version     = var.openshift_version
    pull_secret = file(var.pull_secret_path)
  }

  network_profile {
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
  }

  main_profile {
    vm_size   = var.master_vm_size
    subnet_id = [for k, v in module.vnet.subnets : v.resource_id if k == "control"][0]
  }

  # Worker profile - uses first worker subnet
  worker_profile {
    vm_size      = var.worker_vm_size
    disk_size_gb = var.worker_disk_size_gb
    node_count   = var.worker_node_count
    subnet_id    = [for k, v in module.vnet.subnets : v.resource_id if startswith(k, "worker-")][0]
  }

  service_principal {
    client_id     = var.sp_client_id
    client_secret = var.sp_client_secret
  }

  api_server_profile {
    visibility = var.api_visibility
  }

  ingress_profile {
    visibility = var.ingress_visibility
  }

  tags = var.tags
}
