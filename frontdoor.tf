# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  count = var.create_frontdoor ? 1 : 0

  name                = var.frontdoor_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.tags
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  count = var.create_frontdoor ? 1 : 0

  name                     = "${var.frontdoor_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  tags = var.tags
}

# Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "aro" {
  count = var.create_frontdoor ? 1 : 0

  name                     = "aro-backend"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# Origin
resource "azurerm_cdn_frontdoor_origin" "aro_backend" {
  count = var.create_frontdoor ? 1 : 0

  name                           = "aro-backend"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.aro[0].id
  host_name                      = var.backend_address
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.backend_host_header
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# Route
resource "azurerm_cdn_frontdoor_route" "default" {
  count = var.create_frontdoor ? 1 : 0

  name                          = "default-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aro[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.aro_backend[0].id]

  forwarding_protocol    = "HttpsOnly"
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Https"]
  https_redirect_enabled = true
}
