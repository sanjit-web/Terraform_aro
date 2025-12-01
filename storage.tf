# Storage Account using AVM
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.2"

  count = var.create_storage ? 1 : 0

  name                = var.storage_account_name
  location            = var.location
  resource_group_name = var.resource_group_name

  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind

  blob_properties = {
    versioning_enabled       = var.enable_versioning
    change_feed_enabled      = var.enable_change_feed
    last_access_time_enabled = true
  }

  network_rules = var.enable_private_endpoint ? null : {
    default_action             = var.public_network_access ? "Allow" : "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  private_endpoints = var.enable_private_endpoint ? {
    blob = {
      name               = "${var.storage_account_name}-blob-pe"
      subnet_resource_id = var.private_endpoint_subnet_id
      subresource_name   = "blob"
    }
  } : {}

  containers = {
    registry = {
      name                  = "registry"
      container_access_type = "private"
    }
  }

  tags = var.tags
}
