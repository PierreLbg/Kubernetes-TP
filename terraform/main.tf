terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }

  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_postgresql_server" "pgs-srv" {
  name                = "pgsqlserver-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-plebigre.location
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = data.azurerm_key_vault_secret.database-login.value
  administrator_login_password = data.azurerm_key_vault_secret.database-password.value
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_firewall_rule" "pgs-srv" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  server_name         = azurerm_postgresql_server.pgs-srv.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "example" {
  name                = "TpTerraform"
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  server_name         = azurerm_postgresql_server.pgs-srv.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}