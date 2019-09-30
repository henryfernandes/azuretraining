provider "azurerm" {
}
resource "azurerm_resource_group" "rg" {
        name = "testterra"
        location = "westeurope"
}
