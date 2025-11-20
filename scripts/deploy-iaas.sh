#!/bin/bash
# Deploy IaaS (Infrastructure as a Service) - Azure VMSS with Ansible
# Usage: ./deploy-iaas.sh [environment]

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
SETUP_HTTPS="${SETUP_HTTPS:-true}"

# Load environment config
if [ -f "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env" ]; then
    source "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env"
else
    log_error "Environment config not found: ${ENVIRONMENT}.env"
    exit 1
fi

# Load secrets
if [ -f "${PROJECT_ROOT}/config/.env.local" ]; then
    source "${PROJECT_ROOT}/config/.env.local"
else
    log_warning "Secrets file not found: config/.env.local"
fi

# Main deployment function
main() {
    log_header "IaaS Deployment - ${ENVIRONMENT}"
    
    log_info "Target: Azure VM Scale Set"
    log_info "Environment: ${ENVIRONMENT}"
    log_info "Resource Group: ${AZURE_RESOURCE_GROUP}"
    log_info "Location: ${AZURE_LOCATION}"
    log_info "VMSS: ${VMSS_NAME}"
    echo ""
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN MODE - No changes will be applied"
        echo ""
    fi
    
    # Check prerequisites
    log_step "Step 1: Checking prerequisites"
    check_prerequisites
    
    # Confirm deployment
    if ! confirm "Deploy IaaS to ${ENVIRONMENT}?" "y"; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    # Deploy infrastructure with Terraform
    cd "${PROJECT_ROOT}/terraform"
    
    log_step "Step 2: Initializing Terraform"
    init_terraform
    
    log_step "Step 3: Selecting Terraform workspace"
    select_workspace
    
    log_step "Step 4: Planning infrastructure"
    plan_infrastructure
    
    log_step "Step 5: Applying infrastructure"
    apply_infrastructure
    
    cd "${PROJECT_ROOT}"
    
    # Wait for VMSS instances to be ready
    log_step "Step 6: Waiting for VMSS instances to initialize"
    wait_for_vmss
    
    # Setup Ansible inventory
    log_step "Step 7: Setting up Ansible inventory"
    setup_ansible_inventory
    
    # Run Ansible playbooks
    log_step "Step 8: Installing Docker on VMSS"
    run_ansible_docker
    
    log_step "Step 9: Deploying application"
    run_ansible_deploy
    
    # Setup HTTPS (optional)
    if [ "$SETUP_HTTPS" = "true" ]; then
        log_step "Step 10: Setting up HTTPS with Let's Encrypt"
        setup_https
    else
        log_info "Skipping HTTPS setup"
    fi
    
    # Health check
    log_step "Step 11: Running health checks"
    health_check
    
    # Display summary
    display_summary
}

check_prerequisites() {
    if ! check_all_prerequisites "iaas"; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    # Check SSH key
    if [ -z "${SSH_PRIVATE_KEY_PATH:-}" ]; then
        log_error "SSH_PRIVATE_KEY_PATH not set in config/.env.local"
        exit 1
    fi
    
    # Expand tilde in path
    SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH/#\~/$HOME}"
    
    if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
        log_error "SSH private key not found: $SSH_PRIVATE_KEY_PATH"
        exit 1
    fi
    
    log_success "SSH key found"
    
    # Check terraform.tfvars
    if [ ! -f "${PROJECT_ROOT}/terraform/terraform.tfvars" ]; then
        log_error "terraform.tfvars not found"
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
    if ! terraform workspace list | grep -q "${TERRAFORM_WORKSPACE}"; then
        terraform workspace new "${TERRAFORM_WORKSPACE}"
    else
        terraform workspace select "${TERRAFORM_WORKSPACE}"
    fi
    
    log_success "Using workspace: ${TERRAFORM_WORKSPACE}"
}

plan_infrastructure() {
    log_info "Planning deployment..."
    echo ""
    
    local plan_file="/tmp/tf-iaas-plan-${ENVIRONMENT}.tfplan"
    
    # Plan shared infrastructure + IaaS
    if terraform plan \
        -out="${plan_file}" \
        -target=module.rg \
        -target=module.network \
        -target=module.acr \
        -target=module.mysql \
        -target=module.vmss \
        -target=azurerm_role_assignment.vmss_acr_pull \
        -target=azurerm_mysql_flexible_server_firewall_rule.vmss_to_mysql; then
        log_success "Plan created"
    else
        log_error "Planning failed"
        exit 1
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
    
    log_info "Applying infrastructure..."
    echo ""
    
    local plan_file="/tmp/tf-iaas-plan-${ENVIRONMENT}.tfplan"
    
    if terraform apply "${plan_file}"; then
        log_success "Infrastructure deployed"
    else
        log_error "Deployment failed"
        exit 1
    fi
}

wait_for_vmss() {
    log_info "Waiting for VMSS instances to become ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local instances=$(az vmss list-instances \
            --name "${VMSS_NAME}" \
            --resource-group "${AZURE_RESOURCE_GROUP}" \
            --query "[?provisioningState=='Succeeded'].name" -o tsv 2>/dev/null | wc -l)
        
        if [ "$instances" -gt 0 ]; then
            log_success "$instances instance(s) ready"
            break
        fi
        
        attempt=$((attempt + 1))
        log_info "Waiting... ($attempt/$max_attempts)"
        sleep 10
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_error "Timeout waiting for VMSS instances"
        exit 1
    fi
    
    # Wait additional time for cloud-init
    log_info "Waiting for cloud-init to complete (2 minutes)..."
    sleep 120
    log_success "VMSS instances should be ready"
}

setup_ansible_inventory() {
    cd "${PROJECT_ROOT}/ansible"
    
    log_info "Setting up Ansible inventory..."
    
    # Get VMSS public IPs
    local vmss_ips=$(az vmss list-instance-public-ips \
        --name "${VMSS_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "[].ipAddress" -o tsv 2>/dev/null)
    
    if [ -z "$vmss_ips" ]; then
        log_error "No VMSS public IPs found"
        exit 1
    fi
    
    log_info "Found VMSS IPs:"
    echo "$vmss_ips" | while read ip; do
        echo "  - $ip"
    done
    
    # Create static inventory
    log_info "Creating static inventory..."
    cat > inventory/static.yml << EOF
---
all:
  children:
    vmss_instances:
      hosts:
EOF
    
    local i=1
    echo "$vmss_ips" | while read ip; do
        cat >> inventory/static.yml << EOF
        vmss-instance-${i}:
          ansible_host: ${ip}
          ansible_user: azureuser
          ansible_ssh_private_key_file: ${SSH_PRIVATE_KEY_PATH}
EOF
        i=$((i + 1))
    done
    
    cat >> inventory/static.yml << EOF
      vars:
        acr_name: "${ACR_NAME}"
        acr_login_server: "${ACR_LOGIN_SERVER}"
        docker_image_full: "${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
        app_container_name: "laravel-app"
        app_port: 8080
        mysql_host: "${MYSQL_SERVER_NAME}.mysql.database.azure.com"
        mysql_port: "3306"
        mysql_database: "${MYSQL_DATABASE}"
        mysql_username: "${MYSQL_USERNAME}"
        mysql_password: "${MYSQL_ADMIN_PASSWORD}"
        laravel_app_key: "base64:DJYTvaRkEZ/YcQsX3TMpB0iCjgme2rhlIOus9A1hnj4="
        laravel_app_env: "${ENVIRONMENT}"
        laravel_app_debug: "$([ "$ENVIRONMENT" = "prod" ] && echo "false" || echo "true")"
EOF
    
    log_success "Inventory created: inventory/static.yml"
    
    # Test connectivity
    log_info "Testing SSH connectivity..."
    if ansible all -i inventory/static.yml -m ping 2>/dev/null | grep -q "SUCCESS"; then
        log_success "SSH connectivity OK"
    else
        log_warning "SSH connectivity test failed (may need to wait longer)"
    fi
    
    cd "${PROJECT_ROOT}"
}

run_ansible_docker() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "Skipping Ansible (dry run mode)"
        return
    fi
    
    cd "${PROJECT_ROOT}/ansible"
    
    log_info "Running Docker installation playbook..."
    
    if ansible-playbook -i inventory/static.yml playbooks/docker-only.yml; then
        log_success "Docker installed successfully"
    else
        log_error "Docker installation failed"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
}

run_ansible_deploy() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "Skipping application deployment (dry run mode)"
        return
    fi
    
    cd "${PROJECT_ROOT}/ansible"
    
    log_info "Deploying application..."
    
    if ansible-playbook -i inventory/static.yml playbooks/deploy-app.yml; then
        log_success "Application deployed"
    else
        log_error "Application deployment failed"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
}

setup_https() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "Skipping HTTPS setup (dry run mode)"
        return
    fi
    
    if [ -z "${APP_DOMAIN:-}" ]; then
        log_warning "APP_DOMAIN not set, skipping HTTPS setup"
        return
    fi
    
    cd "${PROJECT_ROOT}/ansible"
    
    log_info "Setting up HTTPS for ${APP_DOMAIN}..."
    
    if confirm "Setup HTTPS with Let's Encrypt?" "y"; then
        if ansible-playbook -i inventory/static.yml playbooks/setup-https.yml \
            -e "domain_name=${APP_DOMAIN}" \
            -e "ssl_email=${SSL_EMAIL}"; then
            log_success "HTTPS configured"
        else
            log_warning "HTTPS setup failed (non-critical)"
        fi
    else
        log_info "Skipping HTTPS setup"
    fi
    
    cd "${PROJECT_ROOT}"
}

health_check() {
    log_info "Running health checks..."
    
    local first_ip=$(az vmss list-instance-public-ips \
        --name "${VMSS_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "[0].ipAddress" -o tsv 2>/dev/null)
    
    if [ -n "$first_ip" ]; then
        log_info "Testing HTTP endpoint: http://${first_ip}"
        
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://${first_ip}" || echo "000")
        
        if [ "$http_code" = "200" ]; then
            log_success "Health check passed (HTTP ${http_code})"
        else
            log_warning "Health check returned HTTP ${http_code}"
        fi
        
        # Test HTTPS if domain is configured
        if [ -n "${APP_DOMAIN:-}" ] && [ "$SETUP_HTTPS" = "true" ]; then
            log_info "Testing HTTPS endpoint: https://${APP_DOMAIN}"
            
            local https_code=$(curl -s -o /dev/null -w "%{http_code}" "https://${APP_DOMAIN}" || echo "000")
            
            if [ "$https_code" = "200" ]; then
                log_success "HTTPS check passed (HTTP ${https_code})"
            else
                log_warning "HTTPS check returned HTTP ${https_code}"
            fi
        fi
    fi
}

display_summary() {
    log_header "Deployment Complete!"
    
    local vmss_ips=$(az vmss list-instance-public-ips \
        --name "${VMSS_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "[].ipAddress" -o tsv 2>/dev/null)
    
    echo ""
    log_success "IaaS deployment to ${ENVIRONMENT} completed successfully"
    echo ""
    log_info "VMSS Instance IPs:"
    echo "$vmss_ips" | while read ip; do
        echo "  - http://${ip}"
    done
    echo ""
    
    if [ -n "${APP_DOMAIN:-}" ] && [ "$SETUP_HTTPS" = "true" ]; then
        log_info "HTTPS URL:"
        echo "  https://${APP_DOMAIN}"
        echo ""
    fi
    
    log_info "Useful commands:"
    echo "  SSH to instance: ssh -i ${SSH_PRIVATE_KEY_PATH} azureuser@<IP>"
    echo "  View containers:  cd ansible && ansible all -i inventory/static.yml -m shell -a 'docker ps' -b"
    echo "  View logs:        cd ansible && ansible all -i inventory/static.yml -m shell -a 'docker logs laravel-app' -b"
    echo ""
}

# Run main function
main "$@"

