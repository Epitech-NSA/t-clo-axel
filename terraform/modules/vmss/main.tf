# Linux Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = var.vm_sku
  instances           = var.initial_instance_count
  admin_username      = var.admin_username
  
  # Use SSH key authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # Disable password authentication for security
  disable_password_authentication = true

  # Source image (Ubuntu 22.04 LTS)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # OS Disk configuration
  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  # Network configuration
  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.lb_backend_pool_id]
      load_balancer_inbound_nat_rules_ids    = var.lb_nat_pool_id != null ? [var.lb_nat_pool_id] : []
    }
  }

  # Cloud-init script to prepare VM for Ansible
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - python3
      - python3-pip
      - curl
      - git
    runcmd:
      - echo "VM ready for Ansible provisioning"
  EOF
  )

  # Managed identity for ACR access
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Auto-scaling profile
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "AutoScale"

    capacity {
      default = var.initial_instance_count
      minimum = var.min_instance_count
      maximum = var.max_instance_count
    }

    # Scale out when CPU > 75%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in when CPU < 25%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.tags
}

