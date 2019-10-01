locals {
  prefix-hub         = "hub"
  hub-location       = "westeurope"
  hub-resource-group = "testterra"
}

resource "azurerm_resource_group" "hub-vnet-rg" {
  name     = local.hub-resource-group
  location = local.hub-location
}

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "${local.prefix-hub}-vnet"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix-hub}-vnet2"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_subnet" "hub-mgmt2" {
  name                 = "mgmt2"
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.1.1.0/24"
}

resource "azurerm_subnet" "hub-mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet" "hub-dmz" {
  name                 = "dmz"
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefix       = "10.0.2.0/24"
}

data "azurerm_virtual_network" "vnet1" {
  name                = azurerm_virtual_network.hub-vnet.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}

data "azurerm_virtual_network" "vnet2" {
  name                = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}


resource "azurerm_virtual_network_peering" "vnet_peer_1" {
  name                         = "vnet_peering_net1"
  resource_group_name          = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name         = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id    = "${data.azurerm_virtual_network.vnet2.id}"
  allow_virtual_network_access = true 
  allow_forwarded_traffic      = true 
  use_remote_gateways          = false 
}

resource "azurerm_virtual_network_peering" "vnet_peer_2" {
  name                         = "vnet_peering_net2"
  resource_group_name          = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = "${data.azurerm_virtual_network.vnet1.id}"
  allow_virtual_network_access = true 
  allow_forwarded_traffic      = true 
  use_remote_gateways          = false 
}

resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_interface" "hub-nic" {
  name                 = "${local.prefix-hub}-nic"
  location             = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = local.prefix-hub
    subnet_id                     = azurerm_subnet.hub-mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_interface" "hub-nic2" {
  name                 = "${local.prefix-hub}-nic2"
  location             = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = local.prefix-hub
    subnet_id                     = azurerm_subnet.hub-mgmt2.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "Terraform Demo"
  }
}
#resource "random_id" "randomId" {
#  keepers = {
#    # Generate a new ID only when a new resource group is defined
#    resource_group = azurerm_resource_group.hub-vnet-rg.name
#  }
#
#  byte_length = 8
#}
#
#resource "azurerm_storage_account" "mystorageaccount" {
#  name                     = "diag${random_id.randomId.hex}"
#  resource_group_name      = azurerm_resource_group.hub-vnet-rg.name
#  location                 = azurerm_resource_group.hub-vnet-rg.location
#  account_replication_type = "LRS"
#  account_tier             = "Standard"
#
#  tags = {
#    environment = "Terraform Demo"
#  }
#}

#Virtual Machine
resource "azurerm_virtual_machine" "hub-vm" {
  name                  = "${local.prefix-hub}-vm"
  location              = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name   = azurerm_resource_group.hub-vnet-rg.name
  network_interface_ids = [azurerm_network_interface.hub-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-hub}-vm"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4Kf4YkSonGxWkY0FTMxw4bi0+D/eZXPd0LLhNjv64mBBJw29H2VynEQnP7sNJikWeZULTP0iuNc9U6bHxskrzap5Osi4HwDbxcIR6HMqRRQk6o+EyEylZZGGIri1YHWw3fEz7KjQi28R0GjR3mgl35btIJ/15Ye3PBLu2EdUKXrNXhMpa1FmnsMT0uUE7gjmitmMzZopOB9EDcpc3aQQ93ZAx0mbkmi3+4lgK+YQav/gGopBvtLGiQEftEU1OTZXNLEYQz37UMWPViQL8AFqU9HFg+XeG877MRAx4MXj58e/ag0lRd5qYSzY+QHLgICmo0F/4w0dHa5jwB71o4S/TymI3Phwfmh5VtLQ35flzEfCfhBzzp/va4X+Q1PI7jD49PDNPfgyRfZvpHNA4SgY3ZnS4ulSsvTQujmmi3WVbMDa1YFkbYu2ao0BSH0Fz0mFoFrd91tgXVR0nZt/7l8uVKvWQseJ7ZbhMsstZ8OkSYLo5Yev3SV/c4T0JvbFQJyk= Administrator@STUDENT16"
    }
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_machine" "hub-vm2" {
  name                  = "${local.prefix-hub}-vm2"
  location              = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name   = azurerm_resource_group.hub-vnet-rg.name
  network_interface_ids = [azurerm_network_interface.hub-nic2.id]
  vm_size               = "Standard_DS1_v2" 

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-hub}-vm2"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4Kf4YkSonGxWkY0FTMxw4bi0+D/eZXPd0LLhNjv64mBBJw29H2VynEQnP7sNJikWeZULTP0iuNc9U6bHxskrzap5Osi4HwDbxcIR6HMqRRQk6o+EyEylZZGGIri1YHWw3fEz7KjQi28R0GjR3mgl35btIJ/15Ye3PBLu2EdUKXrNXhMpa1FmnsMT0uUE7gjmitmMzZopOB9EDcpc3aQQ93ZAx0mbkmi3+4lgK+YQav/gGopBvtLGiQEftEU1OTZXNLEYQz37UMWPViQL8AFqU9HFg+XeG877MRAx4MXj58e/ag0lRd5qYSzY+QHLgICmo0F/4w0dHa5jwB71o4S/TymI3Phwfmh5VtLQ35flzEfCfhBzzp/va4X+Q1PI7jD49PDNPfgyRfZvpHNA4SgY3ZnS4ulSsvTQujmmi3WVbMDa1YFkbYu2ao0BSH0Fz0mFoFrd91tgXVR0nZt/7l8uVKvWQseJ7ZbhMsstZ8OkSYLo5Yev3SV/c4T0JvbFQJyk= Administrator@STUDENT16"
    }
  }

  tags = {
    environment = "Terraform Demo"
  }
}

## Virtual Network Gateway
#resource "azurerm_public_ip" "hub-vpn-gateway1-pip" {
#  name                = "hub-vpn-gateway1-pip"
#  location            = azurerm_resource_group.hub-vnet-rg.location
#  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
#
#  allocation_method = "Dynamic"
#}
#
#resource "azurerm_virtual_network_gateway" "hub-vnet-gateway" {
#  name                = "hub-vpn-gateway1"
#  location            = azurerm_resource_group.hub-vnet-rg.location
#  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
#
#  type     = "Vpn"
#  vpn_type = "RouteBased"
#
#  active_active = false
#  enable_bgp    = false
#  sku           = "VpnGw1"
#
#  ip_configuration {
#    name                          = "vnetGatewayConfig"
#    public_ip_address_id          = azurerm_public_ip.hub-vpn-gateway1-pip.id
#    private_ip_address_allocation = "Dynamic"
#    subnet_id                     = azurerm_subnet.hub-mgmt.id
#  }
#  depends_on = [azurerm_public_ip.hub-vpn-gateway1-pip]
#}

