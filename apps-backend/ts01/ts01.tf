# ----------------------------------------------------------------
# read me
# ----------------------------------------------------------------

# cace - CAnada CEntral 
# bp - blueprint (this tf file)

# dev02ts01
#  ts - trade stats

# ps: 
#   this bp intentionally does not have french version

# ----------------------------------------------------------------
# inputs
# ----------------------------------------------------------------
variable "vm-user" {
  type    = "string"
  default = "adminuser"
}

variable "vm-pass" {
  type    = "string"
  default = "Passwordqwerty1234"
}

variable "vm-count" {
  default = "3"
}

variable "dns-prefix" {
  default = "dev02ts01"
}

# ----------------------------------------------------------------
# toronto azure vm
# ----------------------------------------------------------------
resource "azurerm_resource_group" "az_cace_dev02ts01_resourcegroup01" {
  name     = "az_cace_dev02ts01_resourcegroup01"
  location = "canadacentral"
}

resource "azurerm_virtual_network" "az_cace_dev02ts01_virtualnetwork01" {
  name                = "az_cace_dev02ts01_virtualnetwork01"
  address_space       = ["10.0.0.0/16"]
  location            = "canadacentral"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
}

resource "azurerm_subnet" "az_cace_dev02ts01_subnet01" {
  name                 = "az_cace_dev02ts01_subnet01"
  resource_group_name  = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  virtual_network_name = "${azurerm_virtual_network.az_cace_dev02ts01_virtualnetwork01.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "az_cace_dev02ts01_networksecuritygroup01" {
  name                = "az_cace_dev02ts01_networksecuritygroup01"
  location            = "canadacentral"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"

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
    name                       = "HTTPA"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPB"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "az_cace_dev02ts01_publicip" {
  count                        = "${var.vm-count}"
  name                         = "az_cace_dev02ts01_publicip.${count.index}"
  location                     = "canadacentral"
  resource_group_name          = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "az_cace_dev02ts01_networkinterface" {
  count                     = "${var.vm-count}"
  name                      = "az_cace_dev02ts01_networkinterface.${count.index}"
  location                  = "canadacentral"
  resource_group_name       = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  network_security_group_id = "${azurerm_network_security_group.az_cace_dev02ts01_networksecuritygroup01.id}"

  ip_configuration {
    name                                    = "az_cace_dev02ts01_networkinterface_ipconfig"
    private_ip_address_allocation           = "dynamic"
    subnet_id                               = "${azurerm_subnet.az_cace_dev02ts01_subnet01.id}"
    public_ip_address_id                    = "${element(azurerm_public_ip.az_cace_dev02ts01_publicip.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.az_cace_dev02ts01_lb01_bap01.id}"]
  }
}

resource "azurerm_availability_set" "az_cace_dev02ts01_avset01" {
  name                         = "az_cace_dev02ts01_avset01"
  location                     = "canadacentral"
  managed                      = "true"
  platform_update_domain_count = "6"
  platform_fault_domain_count  = "2"
  resource_group_name          = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
}

resource "azurerm_storage_account" "azcacedevtwots" {
  name                     = "azcacedevtwots"
  resource_group_name      = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  location                 = "canadacentral"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_machine" "az_cace_dev02ts01_vm" {
  count                 = "${var.vm-count}"
  name                  = "az_cace_dev02ts01_vm.${count.index}"
  location              = "canadacentral"
  resource_group_name   = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  network_interface_ids = ["${element(azurerm_network_interface.az_cace_dev02ts01_networkinterface.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.az_cace_dev02ts01_avset01.id}"

  storage_os_disk {
    name              = "az_cace_dev02ts01_storageosdisk.${count.index}"
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
    computer_name  = "ningyo"
    admin_username = "${var.vm-user}"
    admin_password = "${var.vm-pass}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.azcacedevtwots.primary_blob_endpoint}"
  }

  provisioner "file" {
    source      = "seed.tar.gz"
    destination = "/var/tmp/seed.tar.gz"

    connection {
      type     = "ssh"
      host     = "${element(azurerm_public_ip.az_cace_dev02ts01_publicip.*.ip_address, count.index)}"
      port     = "22"
      user     = "${var.vm-user}"
      password = "${var.vm-pass}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /var/tmp/",
      "tar zxf seed.tar.gz",
      "chmod 766 ./seed/index.sh",
      "echo ${var.vm-pass} | sudo -S nohup ./seed/index.sh >> ./seed/index.log &",
      "sleep 1",
    ]

    connection {
      type     = "ssh"
      host     = "${element(azurerm_public_ip.az_cace_dev02ts01_publicip.*.ip_address, count.index)}"
      port     = "22"
      user     = "${var.vm-user}"
      password = "${var.vm-pass}"
    }
  }
}

# ----------------------------------------------------------------
# dns config
# ----------------------------------------------------------------
resource "azurerm_public_ip" "az_cace_dev02ts01_publicip_dns" {
  name                         = "az_cace_dev02ts01_publicip_dns"
  domain_name_label            = "${var.dns-prefix}"
  location                     = "canadacentral"
  resource_group_name          = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "az_cace_dev02ts01_lb01" {
  name                = "az_cace_dev02ts01_lb01"
  location            = "canadacentral"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"

  frontend_ip_configuration {
    name                 = "az_cace_dev02ts01_lb01_ipconfig"
    public_ip_address_id = "${azurerm_public_ip.az_cace_dev02ts01_publicip_dns.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "az_cace_dev02ts01_lb01_bap01" {
  name                = "az_cace_dev02ts01_lb01_bap01"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  loadbalancer_id     = "${azurerm_lb.az_cace_dev02ts01_lb01.id}"
}

resource "azurerm_lb_probe" "az_cace_dev02ts01_lb01_probe01" {
  name                = "az_cace_dev02ts01_lb01_probe01"
  resource_group_name = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  loadbalancer_id     = "${azurerm_lb.az_cace_dev02ts01_lb01.id}"
  protocol            = "HTTP"
  port                = 8080
  request_path        = "/ts/ping"
  interval_in_seconds = "10"
  number_of_probes    = "6"
}

resource "azurerm_lb_rule" "az_cace_dev02ts01_lb01_rule01" {
  name                           = "az_cace_dev02ts01_lb01_rule01"
  frontend_ip_configuration_name = "az_cace_dev02ts01_lb01_ipconfig"
  resource_group_name            = "${azurerm_resource_group.az_cace_dev02ts01_resourcegroup01.name}"
  loadbalancer_id                = "${azurerm_lb.az_cace_dev02ts01_lb01.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.az_cace_dev02ts01_lb01_bap01.id}"
  probe_id                       = "${azurerm_lb_probe.az_cace_dev02ts01_lb01_probe01.id}"

  protocol           = "TCP"
  frontend_port      = 80
  backend_port       = 8080
  enable_floating_ip = false
}

# ----------------------------------------------------------------
# output
# ----------------------------------------------------------------
output "vm_public_ip" {
  description = "static ip of vm"
  value       = ["${azurerm_public_ip.az_cace_dev02ts01_publicip.*.ip_address}"]
}

output "lb_dns_name" {
  description = "load balancer dns"
  value       = "${format("%s%s", var.dns-prefix, ".canadacentral.cloudapp.azure.com")}"
}

output "vm_user" {
  description = "user of vm"
  value       = "${var.vm-user}"
}

output "vm_pass" {
  description = "vm pass"
  value       = "${var.vm-pass}"
}
