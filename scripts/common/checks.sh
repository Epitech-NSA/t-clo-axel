#!/bin/bash
# Prerequisite checks

# Note: logging.sh is already sourced by the calling script

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Azure CLI
check_azure_cli() {
    if ! command_exists az; then
        log_error "Azure CLI is not installed"
        log_info "Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
        return 1
    fi
    
    local version=$(az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4)
    log_success "Azure CLI installed (version: ${version})"
    
    # Check if logged in
    if ! az account show >/dev/null 2>&1; then
        log_error "Not logged into Azure CLI"
        log_info "Run: az login"
        return 1
    fi
    
    local account=$(az account show --query name -o tsv)
    log_success "Logged in to Azure (Account: ${account})"
    return 0
}

# Check Terraform
check_terraform() {
    if ! command_exists terraform; then
        log_error "Terraform is not installed"
        log_info "Install from: https://www.terraform.io/downloads"
        return 1
    fi
    
    local version=$(terraform version 2>/dev/null | head -1 | grep -oP 'v\K[\d\.]+' || echo 'unknown')
    log_success "Terraform installed (version: ${version})"
    return 0
}

# Check Ansible
check_ansible() {
    if ! command_exists ansible; then
        log_error "Ansible is not installed"
        log_info "Install: pip3 install ansible"
        return 1
    fi
    
    local version=$(ansible --version 2>/dev/null | head -1 | awk '{print $3}' | tr -d '[]')
    log_success "Ansible installed (version: ${version})"
    return 0
}

# Check Docker
check_docker() {
    if ! command_exists docker; then
        log_error "Docker is not installed"
        log_info "Install from: https://docs.docker.com/get-docker/"
        return 1
    fi
    
    if ! docker ps >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    local version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    log_success "Docker installed and running (version: ${version})"
    return 0
}

# Check Git
check_git() {
    if ! command_exists git; then
        log_error "Git is not installed"
        return 1
    fi
    
    local version=$(git --version | awk '{print $3}')
    log_success "Git installed (version: ${version})"
    return 0
}

# Check all prerequisites
check_all_prerequisites() {
    local component=$1  # "paas", "iaas", or "all"
    
    log_header "Checking Prerequisites"
    
    local failed=0
    
    # Common checks
    check_azure_cli || ((failed++))
    check_terraform || ((failed++))
    check_git || ((failed++))
    
    # Component-specific checks
    case "$component" in
        iaas|all)
            check_ansible || ((failed++))
            check_docker || ((failed++))
            ;;
        paas)
            check_docker || ((failed++))
            ;;
    esac
    
    echo ""
    
    if [ $failed -eq 0 ]; then
        log_success "All prerequisites met!"
        return 0
    else
        log_error "$failed prerequisite check(s) failed"
        return 1
    fi
}

# Check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ ! -f "$file" ]; then
        log_error "$description not found: $file"
        return 1
    fi
    log_success "$description found"
    return 0
}

# Check if directory exists
check_directory() {
    local dir=$1
    local description=$2
    
    if [ ! -d "$dir" ]; then
        log_error "$description not found: $dir"
        return 1
    fi
    log_success "$description found"
    return 0
}

# Check Azure subscription
check_azure_subscription() {
    local expected_sub="$1"
    
    if [ -z "$expected_sub" ]; then
        log_warning "No subscription ID specified, using current"
        return 0
    fi
    
    local current_sub=$(az account show --query id -o tsv 2>/dev/null)
    
    if [ "$current_sub" != "$expected_sub" ]; then
        log_warning "Current subscription ($current_sub) != expected ($expected_sub)"
        if confirm "Switch to subscription $expected_sub?"; then
            az account set --subscription "$expected_sub"
            log_success "Switched to subscription $expected_sub"
        else
            return 1
        fi
    else
        log_success "Using correct subscription"
    fi
    return 0
}

# Check Terraform state
check_terraform_state() {
    local workspace=$1
    
    if [ ! -d ".terraform" ]; then
        log_warning "Terraform not initialized"
        return 1
    fi
    
    if [ -n "$workspace" ]; then
        local current_workspace=$(terraform workspace show 2>/dev/null)
        if [ "$current_workspace" != "$workspace" ]; then
            log_warning "Current workspace ($current_workspace) != expected ($workspace)"
            return 1
        fi
        log_success "Using correct workspace: $workspace"
    fi
    
    return 0
}

