# ----------------------------------------------------------------
# read me
# ----------------------------------------------------------------

# cace - CAnada CEntral 
# bp - blueprint (this tf file)

# dev02mo01
#  dev - development
#  mo  - mongo

# ps: 
#   this bp intentionally does not have french version

# ----------------------------------------------------------------
# inputs
# ----------------------------------------------------------------
variable "vm-user" {
  type    = "string"
  default = "mongoadmin"
}

variable "vm-pass" {
  type    = "string"
  default = "Passwordqwerty1234"
}

variable "vm-count" {
  default = "1"
}

variable "dns-prefix" {
  default = "dev02mongo"
}

# ----------------------------------------------------------------
# toronto azure vm
# ----------------------------------------------------------------
resource "azurerm_resource_group" "az_cace_dev02mo01_resourcegroup01" {
  name     = "az_cace_dev02mo01_resourcegroup01"
  location = "canadacentral"
}

resource "azurerm_virtual_network" "az_cace_dev02mo01_virtualnetwork01" {
  name                = "az_cace_dev02mo01_virtualnetwork01"
  address_space       = ["10.0.0.0/16"]
  location            = "canadacentral"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
}

resource "azurerm_subnet" "az_cace_dev02mo01_subnet01" {
  name                 = "az_cace_dev02mo01_subnet01"
  resource_group_name  = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
  virtual_network_name = "${azurerm_virtual_network.az_cace_dev02mo01_virtualnetwork01.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "az_cace_dev02mo01_networksecuritygroup01" {
  name                = "az_cace_dev02mo01_networksecuritygroup01"
  location            = "canadacentral"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"

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

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "az_cace_dev02mo01_publicip" {
  count                        = "${var.vm-count}"
  name                         = "az_cace_dev02mo01_publicip.${count.index}"
  location                     = "canadacentral"
  resource_group_name          = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.dns-prefix}${count.index}"
}

resource "azurerm_network_interface" "az_cace_dev02mo01_networkinterface" {
  count                     = "${var.vm-count}"
  name                      = "az_cace_dev02mo01_networkinterface.${count.index}"
  location                  = "canadacentral"
  resource_group_name       = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
  network_security_group_id = "${azurerm_network_security_group.az_cace_dev02mo01_networksecuritygroup01.id}"

  ip_configuration {
    name                          = "az_cace_dev02mo01_networkinterface_ipconfig"
    private_ip_address_allocation = "dynamic"
    subnet_id                     = "${azurerm_subnet.az_cace_dev02mo01_subnet01.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.az_cace_dev02mo01_publicip.*.id, count.index)}"
  }
}

resource "azurerm_availability_set" "az_cace_dev02mo01_avset01" {
  name                         = "az_cace_dev02mo01_avset01"
  location                     = "canadacentral"
  managed                      = "true"
  platform_update_domain_count = "6"
  platform_fault_domain_count  = "2"
  resource_group_name          = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
}

resource "azurerm_storage_account" "azcacedevtwomo" {
  name                     = "azcacedevtwomo"
  resource_group_name      = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
  location                 = "canadacentral"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_machine" "az_cace_dev02mo01_vm" {
  count                 = "${var.vm-count}"
  name                  = "az_cace_dev02mo01_vm.${count.index}"
  location              = "canadacentral"
  resource_group_name   = "${azurerm_resource_group.az_cace_dev02mo01_resourcegroup01.name}"
  network_interface_ids = ["${element(azurerm_network_interface.az_cace_dev02mo01_networkinterface.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.az_cace_dev02mo01_avset01.id}"

  storage_os_disk {
    name              = "az_cace_dev02mo01_storageosdisk.${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  os_profile {
    computer_name  = "mongobox"
    admin_username = "${var.vm-user}"
    admin_password = "${var.vm-pass}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.azcacedevtwomo.primary_blob_endpoint}"
  }

  provisioner "file" {
    source      = "seed.tar.gz"
    destination = "/var/tmp/seed.tar.gz"

    connection {
      type     = "ssh"
      host     = "${element(azurerm_public_ip.az_cace_dev02mo01_publicip.*.ip_address, count.index)}"
      port     = "22"
      user     = "${var.vm-user}"
      password = "${var.vm-pass}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /var/tmp/",                                                              # prepare seed to run
      "tar zxf seed.tar.gz",
      "chmod 766 ./seed/index.sh",
      "echo ${var.vm-pass} | sudo -S nohup ./seed/index.sh >> ./seed/index.log &", # let it run on background until it is done
      "sleep 1",                                                                   # another trick to run provisioner
    ]

    connection {
      type     = "ssh"
      host     = "${element(azurerm_public_ip.az_cace_dev02mo01_publicip.*.ip_address, count.index)}"
      port     = "22"
      user     = "${var.vm-user}"
      password = "${var.vm-pass}"
    }
  }
}

# ----------------------------------------------------------------
# output
# ----------------------------------------------------------------
output "vm_public_ip" {
  description = "mongo vm ip"
  value       = ["${azurerm_public_ip.az_cace_dev02mo01_publicip.*.ip_address}"]
}

output "vm_dns_name" {
  description = "mongo dns"
  value       = ["${formatlist("%s%s", azurerm_public_ip.az_cace_dev02mo01_publicip.*.domain_name_label, ".canadacentral.cloudapp.azure.com")}"]
}

output "vm_user" {
  description = "mongo pass"
  value       = "${var.vm-user}"
}

output "vm_pass" {
  description = "mongo pass"
  value       = "${var.vm-pass}"
}
