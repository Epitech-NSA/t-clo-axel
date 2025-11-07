output "vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "principal_id" {
  description = "Principal ID of the VMSS managed identity"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}

output "unique_id" {
  description = "Unique ID of the VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.unique_id
}

