data "azurerm_advisor_recommendations" "advisor" {

  filter_by_category        = ["Security", "Cost"]
  filter_by_resource_groups = [module.resource_groups["azure_kubernetes_service"].name]
}

data "http" "host_ip" {
  url = "https://api.ipify.org"
}

data "azurerm_subscription" "current" {
}

data "azuread_group" "subscription_owner" {
  display_name = "ris-azr-group-${data.azurerm_subscription.current.display_name}-owner"
}

data "azurerm_client_config" "current" {
}
