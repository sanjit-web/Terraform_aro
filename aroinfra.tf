resource "kubernetes_manifest" "infra" {
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
      replicas = local.current.infra_count

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

          taints = [{
            key    = "infra"
            value  = "reserved"
            effect = "NoSchedule"
          }]

          providerSpec = {
            value = {
              apiVersion = "machine.openshift.io/v1beta1"
              kind       = "AzureMachineProviderSpec"
              location   = var.location
              vmSize     = local.current.infra_vm_size

              osDisk = {
                osType     = "Linux"
                diskSizeGB = local.current.infra_disk_gb
                managedDisk = {
                  storageAccountType = "Premium_LRS"
                }
              }

              publicIP = false
              subnet   = local.worker_subnets["worker-1"].name

              credentialsSecret = {
                name      = "azure-cloud-credentials"
                namespace = "openshift-machine-api"
              }

              vnet                 = var.vnet_name
              resourceGroup        = module.rg_aro.name
              networkResourceGroup = module.resource_group.name

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

resource "kubernetes_manifest" "worker" {
  for_each = { for k, v in local.worker_subnets : k => v if k != "worker-1" }

  depends_on = [azurerm_redhat_openshift_cluster.main]

  manifest = {
    apiVersion = "machine.openshift.io/v1beta1"
    kind       = "MachineSet"

    metadata = {
      name      = "${var.cluster_name}-${each.key}-${var.location}"
      namespace = "openshift-machine-api"
      labels = {
        "machine.openshift.io/cluster-api-cluster"      = var.cluster_name
        "machine.openshift.io/cluster-api-machine-role" = "worker"
        "machine.openshift.io/cluster-api-machine-type" = "worker"
      }
    }

    spec = {
      replicas = local.current.worker_count_per_pool

      selector = {
        matchLabels = {
          "machine.openshift.io/cluster-api-cluster"    = var.cluster_name
          "machine.openshift.io/cluster-api-machineset" = "${var.cluster_name}-${each.key}-${var.location}"
        }
      }

      template = {
        metadata = {
          labels = {
            "machine.openshift.io/cluster-api-cluster"      = var.cluster_name
            "machine.openshift.io/cluster-api-machine-role" = "worker"
            "machine.openshift.io/cluster-api-machine-type" = "worker"
            "machine.openshift.io/cluster-api-machineset"   = "${var.cluster_name}-${each.key}-${var.location}"
            "subnet"                                        = each.key
          }
        }

        spec = {
          metadata = {
            labels = {
              "node-role.kubernetes.io/worker" = ""
              "subnet"                         = each.key
            }
          }

          providerSpec = {
            value = {
              apiVersion = "machine.openshift.io/v1beta1"
              kind       = "AzureMachineProviderSpec"
              location   = var.location
              vmSize     = local.current.worker_vm_size

              osDisk = {
                osType     = "Linux"
                diskSizeGB = local.current.worker_disk_gb
                managedDisk = {
                  storageAccountType = "Premium_LRS"
                }
              }

              publicIP = false
              subnet   = each.value.name

              credentialsSecret = {
                name      = "azure-cloud-credentials"
                namespace = "openshift-machine-api"
              }

              vnet                 = var.vnet_name
              resourceGroup        = module.rg_aro.name
              networkResourceGroup = module.resource_group.name

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
