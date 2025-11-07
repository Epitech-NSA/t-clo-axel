output "lb_id" {
  description = "ID of the Load Balancer"
  value       = azurerm_lb.lb.id
}

output "lb_name" {
  description = "Name of the Load Balancer"
  value       = azurerm_lb.lb.name
}

output "backend_pool_id" {
  description = "ID of the backend address pool"
  value       = azurerm_lb_backend_address_pool.backend_pool.id
}

output "public_ip_address" {
  description = "Public IP address of the Load Balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "lb_frontend_ip" {
  description = "Frontend IP configuration name"
  value       = azurerm_lb.lb.frontend_ip_configuration[0].name
}

output "nat_pool_id" {
  description = "ID of the SSH NAT pool"
  value       = azurerm_lb_nat_pool.ssh_nat_pool.id
}

