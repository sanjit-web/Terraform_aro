# Resource Group using AVM
module "rg_aro" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.1"
  
  name     = var.resource_group_name
  location = var.location
  
  tags = var.tags
}

# Infrastructure MachineSet using Kubernetes provider
resource "kubernetes_manifest" "infra_machineset" {
  depends_on = [azurerm_redhat_openshift_cluster.main]

  manifest = {
    apiVersion = "machine.openshift.io/v1beta1"
    kind       = "MachineSet"
    
    metadata = {
      name      = "${var.cluster_name}-infra-${var.location}"
      namespace = "openshift-machine-api"
      labels = {
        "machine.openshift.io/cluster-api-cluster"      = var.cluster_name
        "machine.openshift.io/cluster-api-machine-role" = "infra"
        "machine.openshift.io/cluster-api-machine-type" = "infra"
      }
    }
    
    spec = {
      replicas = var.infra_node_count
      
      selector = {
        matchLabels = {
          "machine.openshift.io/cluster-api-cluster"    = var.cluster_name
          "machine.openshift.io/cluster-api-machineset" = "${var.cluster_name}-infra-${var.location}"
        }
      }
      
      template = {
        metadata = {
          labels = {
            "machine.openshift.io/cluster-api-cluster"      = var.cluster_name
            "machine.openshift.io/cluster-api-machine-role" = "infra"
            "machine.openshift.io/cluster-api-machine-type" = "infra"
            "machine.openshift.io/cluster-api-machineset"   = "${var.cluster_name}-infra-${var.location}"
          }
        }
        
        spec = {
          metadata = {
            labels = {
              "node-role.kubernetes.io/infra" = ""
            }
          }
          
          taints = [
            {
              key    = "infra"
              value  = "reserved"
              effect = "NoSchedule"
            }
          ]
          
          providerSpec = {
            value = {
              apiVersion = "machine.openshift.io/v1beta1"
              kind       = "AzureMachineProviderSpec"
              
              vmSize = var.infra_vm_size
              
              osDisk = {
                osType = "Linux"
                diskSizeGB = var.infra_disk_size_gb
                managedDisk = {
                  storageAccountType = "Premium_LRS"
                }
              }
              
              publicIP             = false
              subnet               = [for k, v in module.vnet.subnets : k if startswith(k, "worker-")][0]
              vnet                 = var.vnet_name
              resourceGroup        = var.resource_group_name
              networkResourceGroup = var.resource_group_name
              
              credentialsSecret = {
                name      = "azure-cloud-credentials"
                namespace = "openshift-machine-api"
              }
              
              image = {
                publisher = "azureopenshift"
                offer     = "aro4"
                sku       = "aro_${replace(var.openshift_version, ".", "")}"
                version   = "latest"
              }
            }
          }
        }
      }
    }
  }
}

# Worker MachineSets (one per subnet)
resource "kubernetes_manifest" "worker_machineset" {
  for_each = { for k, v in module.vnet.subnets : k => v if startswith(k, "worker-") }
  
  depends_on = [azurerm_redhat_openshift_cluster.main]

  manifest = {
    apiVersion = "machine.openshift.io/v1beta1"
    kind       = "MachineSet"
    
    metadata = {
      name      = "${var.cluster_name}-worker-${split("-", each.key)[1]}"
      namespace = "openshift-machine-api"
      labels = {
        "machine.openshift.io/cluster-api-cluster"      = var.cluster_name
        "machine.openshift.io/cluster-api-machine-role" = "worker"
        "machine.openshift.io/cluster-api-machine-type" = "worker"
      }
    }
    
    spec = {
      replicas = var.worker_node_count_per_pool
      
      selector = {
        matchLabels = {
          "machine.openshift.io/cluster-api-cluster"    = var.cluster_name
          "machine.openshift.io/cluster-api-machineset" = "${var.cluster_name}-worker-${split("-", each.key)[1]}"
        }
      }
      
      template = {
        metadata = {
          labels = {
            "machine.openshift.io/cluster-api-cluster"      = var.cluster_name
            "machine.openshift.io/cluster-api-machine-role" = "worker"
            "machine.openshift.io/cluster-api-machine-type" = "worker"
            "machine.openshift.io/cluster-api-machineset"   = "${var.cluster_name}-worker-${split("-", each.key)[1]}"
          }
        }
        
        spec = {
          metadata = {
            labels = {
              "node-role.kubernetes.io/worker" = ""
            }
          }
          
          providerSpec = {
            value = {
              apiVersion = "machine.openshift.io/v1beta1"
              kind       = "AzureMachineProviderSpec"
              
              vmSize = var.worker_vm_size
              
              osDisk = {
                osType = "Linux"
                diskSizeGB = var.worker_disk_size_gb
                managedDisk = {
                  storageAccountType = "Premium_LRS"
                }
              }
              
              publicIP             = false
              subnet               = each.key
              vnet                 = var.vnet_name
              resourceGroup        = var.resource_group_name
              networkResourceGroup = var.resource_group_name
              
              credentialsSecret = {
                name      = "azure-cloud-credentials"
                namespace = "openshift-machine-api"
              }
              
              image = {
                publisher = "azureopenshift"
                offer     = "aro4"
                sku       = "aro_${replace(var.openshift_version, ".", "")}"
                version   = "latest"
              }
            }
          }
        }
      }
    }
  }
}
