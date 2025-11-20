#!/bin/bash
# Destroy Infrastructure - Cleanup resources
# Usage: ./destroy-environment.sh [environment] [component]
#   component: paas, iaas, all

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source utilities
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/checks.sh"

# Configuration
ENVIRONMENT="${1:-dev}"
COMPONENT="${2:-all}"  # paas, iaas, or all

# Load environment config
if [ -f "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env" ]; then
    source "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env"
else
    log_error "Environment config not found: ${ENVIRONMENT}.env"
    exit 1
fi

# Main function
main() {
    log_header "Destroy Infrastructure - ${ENVIRONMENT}"
    
    log_warning "This will DESTROY resources in ${ENVIRONMENT} environment!"
    log_info "Component: ${COMPONENT}"
    log_info "Resource Group: ${AZURE_RESOURCE_GROUP}"
    echo ""
    
    # Confirm destruction
    if [ "$ENVIRONMENT" = "prod" ]; then
        log_error "PRODUCTION ENVIRONMENT!"
        echo ""
        if ! confirm "Type 'DELETE-PROD' to confirm destruction" "n"; then
            log_info "Destruction cancelled"
            exit 0
        fi
        
        read -p "Type 'DELETE-PROD' exactly: " confirmation
        if [ "$confirmation" != "DELETE-PROD" ]; then
            log_error "Confirmation failed"
            exit 1
        fi
    else
        if ! confirm "Are you sure you want to destroy ${COMPONENT} in ${ENVIRONMENT}?" "n"; then
            log_info "Destruction cancelled"
            exit 0
        fi
    fi
    
    cd "${PROJECT_ROOT}/terraform"
    
    # Initialize and select workspace
    log_step "Step 1: Preparing Terraform"
    prepare_terraform
    
    # Destroy based on component
    case "$COMPONENT" in
        paas)
            destroy_paas
            ;;
        iaas)
            destroy_iaas
            ;;
        all)
            destroy_all
            ;;
        *)
            log_error "Invalid component: $COMPONENT (use: paas, iaas, or all)"
            exit 1
            ;;
    esac
    
    log_header "Destruction Complete"
    log_success "Resources have been destroyed"
    
    cd "${PROJECT_ROOT}"
}

prepare_terraform() {
    terraform init >/dev/null 2>&1
    terraform workspace select "${TERRAFORM_WORKSPACE}" >/dev/null 2>&1
    log_success "Terraform ready (workspace: ${TERRAFORM_WORKSPACE})"
}

destroy_paas() {
    log_step "Destroying PaaS resources"
    
    log_warning "This will destroy:"
    echo "  - App Service: ${APP_SERVICE_NAME}"
    echo "  - App Service Plan: ${APP_SERVICE_PLAN}"
    echo ""
    
    if ! confirm "Continue with PaaS destruction?" "n"; then
        log_info "Cancelled"
        return
    fi
    
    log_info "Destroying PaaS..."
    
    if terraform destroy \
        -target=module.appservice \
        -target=azurerm_role_assignment.webapp_acr_pull \
        -auto-approve; then
        log_success "PaaS resources destroyed"
    else
        log_error "Failed to destroy some PaaS resources"
        log_info "Check Terraform state for remaining resources"
    fi
}

destroy_iaas() {
    log_step "Destroying IaaS resources"
    
    log_warning "This will destroy:"
    echo "  - VMSS: ${VMSS_NAME}"
    echo "  - All VM instances"
    echo "  - Public IPs"
    echo ""
    
    if ! confirm "Continue with IaaS destruction?" "n"; then
        log_info "Cancelled"
        return
    fi
    
    log_info "Destroying IaaS..."
    
    if terraform destroy \
        -target=module.vmss \
        -target=azurerm_role_assignment.vmss_acr_pull \
        -target=azurerm_mysql_flexible_server_firewall_rule.vmss_to_mysql \
        -auto-approve; then
        log_success "IaaS resources destroyed"
    else
        log_error "Failed to destroy some IaaS resources"
    fi
}

destroy_all() {
    log_step "Destroying ALL resources"
    
    log_error "This will destroy EVERYTHING in ${ENVIRONMENT}:"
    echo "  - All PaaS resources"
    echo "  - All IaaS resources"
    echo "  - Shared infrastructure (VNet, ACR, MySQL)"
    echo "  - ALL DATA WILL BE LOST!"
    echo ""
    
    if ! confirm "Destroy EVERYTHING in ${ENVIRONMENT}?" "n"; then
        log_info "Cancelled"
        return
    fi
    
    log_info "Destroying all resources..."
    
    if terraform destroy -auto-approve; then
        log_success "All resources destroyed"
    else
        log_error "Failed to destroy all resources"
        log_info "Some resources may remain - check manually"
    fi
}

# Run main function
main "$@"

