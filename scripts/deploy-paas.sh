#!/bin/bash
# Deploy PaaS (Platform as a Service) - Azure App Service
# Usage: ./deploy-paas.sh [environment]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source utilities
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/checks.sh"

# Configuration
ENVIRONMENT="${1:-dev}"
DRY_RUN="${DRY_RUN:-false}"

# Load environment config
if [ -f "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env" ]; then
    source "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env"
else
    log_error "Environment config not found: ${ENVIRONMENT}.env"
    exit 1
fi

# Load secrets if available
if [ -f "${PROJECT_ROOT}/config/.env.local" ]; then
    source "${PROJECT_ROOT}/config/.env.local"
else
    log_warning "Secrets file not found: config/.env.local"
    log_info "Some operations may fail without proper credentials"
fi

# Main deployment function
main() {
    log_header "PaaS Deployment - ${ENVIRONMENT}"
    
    log_info "Target: Azure App Service"
    log_info "Environment: ${ENVIRONMENT}"
    log_info "Resource Group: ${AZURE_RESOURCE_GROUP}"
    log_info "Location: ${AZURE_LOCATION}"
    log_info "App Service: ${APP_SERVICE_NAME}"
    echo ""
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN MODE - No changes will be applied"
        echo ""
    fi
    
    # Check prerequisites
    log_step "Step 1: Checking prerequisites"
    check_prerequisites
    
    # Confirm deployment
    if ! confirm "Deploy PaaS to ${ENVIRONMENT}?" "y"; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    # Navigate to terraform directory
    cd "${PROJECT_ROOT}/terraform"
    
    # Initialize Terraform
    log_step "Step 2: Initializing Terraform"
    init_terraform
    
    # Select workspace
    log_step "Step 3: Selecting Terraform workspace"
    select_workspace
    
    # Plan infrastructure
    log_step "Step 4: Planning infrastructure (shared + PaaS)"
    plan_infrastructure
    
    # Apply infrastructure
    log_step "Step 5: Applying infrastructure"
    apply_infrastructure
    
    # Verify deployment
    log_step "Step 6: Verifying deployment"
    verify_deployment
    
    # Configure application
    log_step "Step 7: Configuring application"
    configure_application
    
    # Run migrations
    log_step "Step 8: Running database migrations"
    run_migrations
    
    # Health check
    log_step "Step 9: Running health checks"
    health_check
    
    # Display summary
    display_summary
    
    cd "${PROJECT_ROOT}"
}

check_prerequisites() {
    if ! check_all_prerequisites "paas"; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "${PROJECT_ROOT}/terraform/terraform.tfvars" ]; then
        log_error "terraform.tfvars not found"
        log_info "Create it from terraform.tfvars.example"
        exit 1
    fi
    
    # Verify Azure subscription
    check_azure_subscription "${AZURE_SUBSCRIPTION_ID}"
}

init_terraform() {
    log_info "Initializing Terraform..."
    
    if terraform init -upgrade; then
        log_success "Terraform initialized"
    else
        log_error "Terraform initialization failed"
        exit 1
    fi
}

select_workspace() {
    log_info "Current workspace: $(terraform workspace show)"
    
    # Create workspace if it doesn't exist
    if ! terraform workspace list | grep -q "${TERRAFORM_WORKSPACE}"; then
        log_info "Creating workspace: ${TERRAFORM_WORKSPACE}"
        terraform workspace new "${TERRAFORM_WORKSPACE}"
    else
        terraform workspace select "${TERRAFORM_WORKSPACE}"
    fi
    
    log_success "Using workspace: ${TERRAFORM_WORKSPACE}"
}

plan_infrastructure() {
    log_info "Planning deployment..."
    echo ""
    
    local plan_file="/tmp/tf-paas-plan-${ENVIRONMENT}.tfplan"
    
    # Plan shared infrastructure + PaaS
    if terraform plan \
        -out="${plan_file}" \
        -target=module.rg \
        -target=module.network \
        -target=module.acr \
        -target=module.mysql \
        -target=module.appservice \
        -target=azurerm_role_assignment.webapp_acr_pull; then
        log_success "Plan created successfully"
        echo ""
        log_info "Plan saved to: ${plan_file}"
    else
        log_error "Planning failed"
        exit 1
    fi
    
    # Show estimated costs (if available)
    if command_exists infracost; then
        log_info "Estimating costs..."
        infracost breakdown --path="${plan_file}" || log_warning "Cost estimation failed"
    fi
    
    echo ""
    if ! confirm "Apply this plan?" "y"; then
        log_info "Deployment cancelled"
        exit 0
    fi
}

apply_infrastructure() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "Skipping apply (dry run mode)"
        return
    fi
    
    log_info "Applying infrastructure changes..."
    echo ""
    
    local plan_file="/tmp/tf-paas-plan-${ENVIRONMENT}.tfplan"
    
    if terraform apply "${plan_file}"; then
        log_success "Infrastructure deployed successfully"
    else
        log_error "Deployment failed"
        log_info "Check Terraform state for any partial deployments"
        exit 1
    fi
}

verify_deployment() {
    log_info "Verifying App Service deployment..."
    
    # Check if App Service exists
    if az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "state" -o tsv 2>/dev/null | grep -q "Running"; then
        log_success "App Service is running"
    else
        log_error "App Service not found or not running"
        exit 1
    fi
    
    # Check if MySQL is running
    if az mysql flexible-server show \
        --name "${MYSQL_SERVER_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "state" -o tsv 2>/dev/null | grep -q "Ready"; then
        log_success "MySQL server is ready"
    else
        log_warning "MySQL server state check failed"
    fi
}

configure_application() {
    log_info "Configuring application settings..."
    
    # Get App Service URL
    local app_url=$(az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "defaultHostName" -o tsv 2>/dev/null)
    
    if [ -n "$app_url" ]; then
        log_success "App URL: https://${app_url}"
    else
        log_warning "Could not retrieve app URL"
    fi
}

run_migrations() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "Skipping migrations (dry run mode)"
        return
    fi
    
    log_info "Running Laravel database migrations..."
    
    # Try to run migrations via Kudu API or SSH
    if confirm "Run database migrations now?" "y"; then
        log_info "Connecting to App Service..."
        
        # Method 1: Via SSH
        if az webapp ssh \
            --name "${APP_SERVICE_NAME}" \
            --resource-group "${AZURE_RESOURCE_GROUP}" \
            --command "cd /var/www/html && php artisan migrate --force" 2>/dev/null; then
            log_success "Migrations completed"
        else
            log_warning "Could not run migrations automatically"
            log_info "You can run manually:"
            echo "  az webapp ssh --name ${APP_SERVICE_NAME} --resource-group ${AZURE_RESOURCE_GROUP}"
            echo "  cd /var/www/html && php artisan migrate --force"
        fi
    else
        log_info "Skipping migrations"
    fi
}

health_check() {
    log_info "Running health checks..."
    
    local app_url="https://$(az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "defaultHostName" -o tsv 2>/dev/null)"
    
    if [ -n "$app_url" ]; then
        log_info "Testing endpoint: ${app_url}"
        
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "${app_url}" || echo "000")
        
        if [ "$http_code" = "200" ]; then
            log_success "Health check passed (HTTP ${http_code})"
        else
            log_warning "Health check returned HTTP ${http_code}"
            log_info "The application may still be starting up"
        fi
    else
        log_warning "Could not determine app URL for health check"
    fi
}

display_summary() {
    log_header "Deployment Complete!"
    
    local app_url=$(az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "defaultHostName" -o tsv 2>/dev/null)
    
    echo ""
    log_success "PaaS deployment to ${ENVIRONMENT} completed successfully"
    echo ""
    log_info "Application URL:"
    echo "  https://${app_url}"
    echo ""
    log_info "Azure Portal:"
    echo "  https://portal.azure.com/#@/resource/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_SERVICE_NAME}"
    echo ""
    log_info "Useful commands:"
    echo "  View logs:  az webapp log tail --name ${APP_SERVICE_NAME} --resource-group ${AZURE_RESOURCE_GROUP}"
    echo "  SSH access: az webapp ssh --name ${APP_SERVICE_NAME} --resource-group ${AZURE_RESOURCE_GROUP}"
    echo "  Restart:    az webapp restart --name ${APP_SERVICE_NAME} --resource-group ${AZURE_RESOURCE_GROUP}"
    echo ""
}

# Run main function
main "$@"

