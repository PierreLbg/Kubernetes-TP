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

  administrator_login          = data.azurerm_key_vault_secret.database-login.value
  administrator_login_password = data.azurerm_key_vault_secret.database-password.value

  sku_name   = "GP_Gen5_4"
  version    = "11"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_postgresql_firewall_rule" "pgs-firewall" {
  name             = "pgs-firewall"
  server_name        = azurerm_postgresql_server.pgs-srv.name
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_database" "pgs-db" {
  name                = "pgs-db"
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  server_name         = azurerm_postgresql_server.pgs-srv.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_container_group" "pgadmin" {
  name                = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  location            = data.azurerm_resource_group.rg-plebigre.location
  ip_address_type     = "Public"
  dns_name_label      = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "PGADMIN_DEFAULT_EMAIL" = data.azurerm_key_vault_secret.pgadmin-login.value,
      "PGADMIN_DEFAULT_PASSWORD" = data.azurerm_key_vault_secret.pgadmin-password.value
    }
  }
}


resource "azurerm_service_plan" "app-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  location            = data.azurerm_resource_group.rg-plebigre.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "web-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-plebigre.name
  location            = data.azurerm_resource_group.rg-plebigre.location
  service_plan_id     = azurerm_service_plan.app-plan.id

  site_config { 
    application_stack {
      node_version = "16-lts"
    }
  }

  app_settings = {
    "PORT"="3000",
    "DB_HOST"=azurerm_postgresql_server.pgs-srv.fqdn,
    "DB_USERNAME" = "${data.azurerm_key_vault_secret.database-login.value}@${azurerm_postgresql_server.pgs-srv.name}",
    "DB_PASSWORD"=data.azurerm_key_vault_secret.database-password.value,
    "DB_DATABASE"=azurerm_postgresql_database.pgs-db.name,
    "DB_DAILECT"="postgres",
    "DB_PORT"="5432",
    "ACCESS_TOKEN_SECRET"="YOUR_SECRET_KEY",
    "REFRESH_TOKEN_SECRET"="YOUR_SECRET_KEY",
    "ACCESS_TOKEN_EXPIRY"="15m",
    "REFRESH_TOKEN_EXPIRY"="7d",
    "REFRESH_TOKEN_COOKIE_NAME"="jid"
  }
}