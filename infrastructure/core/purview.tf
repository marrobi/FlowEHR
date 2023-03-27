#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.

resource "azurerm_purview_account" "core" {
  count = var.purview.enabled ? 1 : 0

  name                   = "purview-${var.naming_suffix}"
  resource_group_name    = azurerm_resource_group.core.name
  location               = azurerm_resource_group.core.location
  public_network_enabled = var.purview.public_network_enabled
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_dns_zone" "purview_account" {
  count               = !var.purview.public_network_enabled && var.purview.enabled ? 1 : 0
  name                = "privatelink.purview.azure.com"
  resource_group_name = azurerm_resource_group.core.name
}

resource "azurerm_private_dns_zone" "purview_portal" {
  count               = !var.purview.public_network_enabled && var.purview.enabled ? 1 : 0
  name                = "privatelink.purviewstudio.azure.com"
  resource_group_name = azurerm_resource_group.core.name
}

resource "azurerm_private_endpoint" "core_purview_account" {
  count = !var.purview.public_network_enabled && var.purview.enabled ? 1 : 0

  name                = "purview-account-${var.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.core_shared.id

  private_service_connection {
    name                           = "purview-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_purview_account.core[0].id
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "purview-account-${var.naming_suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.purview_account[0].id]
  }
}

resource "azurerm_private_endpoint" "core_purview_portal" {
  count = !var.purview.public_network_enabled && var.purview.enabled ? 1 : 0

  name                = "purview-portal-${var.naming_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.core_shared.id

  private_service_connection {
    name                           = "purview-${var.naming_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_purview_account.core[0].id
    subresource_names              = ["portal"]
  }

  private_dns_zone_group {
    name                 = "purview-portal-${var.naming_suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.purview_portal[0].id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "core_purview_account" {
  count = !var.purview.public_network_enabled && var.purview.enabled ? 1 : 0

  name                  = "nl-purviewaccount-${var.naming_suffix}"
  resource_group_name   = azurerm_resource_group.core.name
  private_dns_zone_name = azurerm_private_dns_zone.purview_account[0].name
  virtual_network_id    = azurerm_virtual_network.core.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "core_purview_portal" {
  count = !var.purview.public_network_enabled && var.purview.enabled ? 1 : 0

  name                  = "nl-purviewportal-${var.naming_suffix}"
  resource_group_name   = azurerm_resource_group.core.name
  private_dns_zone_name = azurerm_private_dns_zone.purview_portal[0].name
  virtual_network_id    = azurerm_virtual_network.core.id
}
