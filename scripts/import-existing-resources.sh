#!/bin/bash
# Import existing Azure resources into Terraform state
# This script helps recover from situations where resources exist in Azure but not in Terraform state

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source utilities
source "${SCRIPT_DIR}/common/logging.sh"

# Configuration
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
SUBSCRIPTION_ID="6b9318b1-2215-418a-b0fd-ba0832e9b333"
RESOURCE_GROUP="rg-nan_1"

main() {
    log_header "Import Existing Resources into Terraform State"
    
    local environment=${1:-dev}
    
    log_info "Environment: $environment"
    log_info "This will import existing Azure resources into Terraform state"
    echo ""
    
    if ! confirm "Continue with import?" "y"; then
        log_info "Import cancelled"
        exit 0
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Select workspace
    log_step "Selecting Terraform workspace: $environment"
    terraform workspace select "$environment" || {
        log_error "Failed to select workspace $environment"
        exit 1
    }
    
    # Import resources
    import_resources "$environment"
    
    log_header "Import Complete!"
    log_success "Resources have been imported into Terraform state"
    echo ""
    log_info "Next steps:"
    echo "  1. Run: make dev-paas (or make dev-iaas)"
    echo "  2. Terraform will now manage these existing resources"
    echo ""
}

import_resources() {
    local env=$1
    local prefix="tc-${env}"
    
    log_step "Importing existing resources"
    
    # List of common resources that might exist
    declare -A resources=(
        # MySQL Server
        ["mysql"]="module.mysql.azurerm_mysql_flexible_server.this|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.DBforMySQL/flexibleServers/${prefix}-mysql-frc-01"
        
        # Network associations (use subnet ID only for NSG associations)
        ["subnet-web-nsg"]="module.network.azurerm_subnet_network_security_group_association.assoc[\"subnet-web\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01/subnets/subnet-web"
        ["subnet-vmss-nsg"]="module.network.azurerm_subnet_network_security_group_association.assoc[\"subnet-vmss\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01/subnets/subnet-vmss"
        ["subnet-app-nsg"]="module.network.azurerm_subnet_network_security_group_association.assoc[\"subnet-app\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01/subnets/subnet-app"
        
        # ACR
        ["acr"]="module.acr.azurerm_container_registry.this|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerRegistry/registries/${prefix}acrfrc01"
        
        # VNet
        ["vnet"]="module.network.azurerm_virtual_network.vnet|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01"
        
        # Subnets
        ["subnet-web"]="module.network.azurerm_subnet.subnet[\"subnet-web\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01/subnets/subnet-web"
        ["subnet-vmss"]="module.network.azurerm_subnet.subnet[\"subnet-vmss\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01/subnets/subnet-vmss"
        ["subnet-app"]="module.network.azurerm_subnet.subnet[\"subnet-app\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${prefix}-vnet-frc-01/subnets/subnet-app"
        
        # NSGs
        ["nsg-web"]="module.network.azurerm_network_security_group.nsg[\"subnet-web\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
        ["nsg-vmss"]="module.network.azurerm_network_security_group.nsg[\"subnet-vmss\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/networkSecurityGroups/nsg-vmss"
        ["nsg-app"]="module.network.azurerm_network_security_group.nsg[\"subnet-app\"]|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
        
        # App Service (PaaS)
        ["app-service-plan"]="module.appservice.azurerm_service_plan.this|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/serverFarms/${prefix}-asp-frc-01"
        ["web-app"]="module.appservice.azurerm_linux_web_app.this|/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${prefix}-web-frc-01"
    )
    
    local imported=0
    local skipped=0
    local failed=0
    
    for resource_name in "${!resources[@]}"; do
        IFS='|' read -r tf_address azure_id <<< "${resources[$resource_name]}"
        
        log_info "Checking: $resource_name"
        
        # Check if resource already in state
        if terraform state show "$tf_address" &>/dev/null; then
            log_warning "  Already in state, skipping"
            skipped=$((skipped + 1))
            continue
        fi
        
        # Try to import
        if terraform import "$tf_address" "$azure_id" &>/dev/null; then
            log_success "  Imported successfully"
            imported=$((imported + 1))
        else
            log_warning "  Not found in Azure or failed to import (this is normal if resource doesn't exist)"
            failed=$((failed + 1))
        fi
    done
    
    echo ""
    log_info "Summary: $imported imported, $skipped skipped, $failed not found"
}

# Run main
main "$@"

