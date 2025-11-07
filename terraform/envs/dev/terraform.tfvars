# Terraform Variables for Development Environment
# Copy this file to terraform.tfvars and fill in the values

mysql_admin_password = "YourSecurePassword123!"

ssh_public_key_iaas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkWWaahsTfBH/uNumIr9PKJltm/ZLgKCCGEvyTJ1Htc your_email@example.com"

# Optional: Override default values if needed
environment = "dev"
location = "francecentral"
app_service_sku = "B1"
mysql_sku = "B_Standard_B1ms"
vm_sku = "Standard_B2s"
