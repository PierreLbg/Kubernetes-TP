data "azurerm_resource_group" "rg-plebigre" {
  name = "rg-${var.project_name}${var.environment_suffix}"
}

data "azurerm_key_vault" "kv"{
    resource_group_name = data.azurerm_resource_group.rg-plebigre.name
    name = "kv-${var.project_name}${var.environment_suffix}"
}

data "azurerm_key_vault_secret" "database-login"{
    name = "database-login"
    key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "database-password"{
    name = "database-password"
    key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "pgadmin-login"{
    name = "pgadmin-login"
    key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "pgadmin-password"{
    name = "pgadmin-password"
    key_vault_id = data.azurerm_key_vault.kv.id
}