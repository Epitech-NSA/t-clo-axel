#!/bin/bash
# Setup Development Environment
# This script installs all necessary dependencies and configures the environment

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source utilities
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/checks.sh"

# Main setup function
main() {
    log_header "Environment Setup - TERRACLOUD Project"
    
    log_info "This script will install and configure all required tools"
    echo ""
    
    if ! confirm "Continue with environment setup?" "y"; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    # Step 1: Check current installations
    log_step "Step 1: Checking current installations"
    check_current_installations
    
    # Step 2: Install missing dependencies
    log_step "Step 2: Installing missing dependencies"
    install_dependencies
    
    # Step 3: Configure Azure CLI
    log_step "Step 3: Configuring Azure CLI"
    configure_azure
    
    # Step 4: Setup Terraform
    log_step "Step 4: Setting up Terraform"
    setup_terraform
    
    # Step 5: Setup Ansible
    log_step "Step 5: Setting up Ansible"
    setup_ansible
    
    # Step 6: Generate SSH keys if needed
    log_step "Step 6: Setting up SSH keys"
    setup_ssh_keys
    
    # Step 7: Create local configuration
    log_step "Step 7: Creating local configuration"
    setup_local_config
    
    # Step 8: Verify everything
    log_step "Step 8: Final verification"
    verify_setup
    
    log_header "Setup Complete!"
    log_success "Your environment is ready for deployment"
    echo ""
    log_info "Next steps:"
    echo "  1. Edit config/.env.local with your secrets"
    echo "  2. Run: make dev-paas  (for PaaS deployment)"
    echo "  3. Run: make dev-iaas  (for IaaS deployment)"
    echo ""
}

check_current_installations() {
    local installed=0
    local missing=0
    
    # Azure CLI
    if command_exists az; then
        log_success "Azure CLI: $(az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4)"
        installed=$((installed + 1))
    else
        log_warning "Azure CLI: Not installed"
        missing=$((missing + 1))
    fi
    
    # Terraform
    if command_exists terraform; then
        log_success "Terraform: $(terraform version 2>/dev/null | head -1 | grep -oP 'v\K[\d\.]+' || echo 'unknown')"
        installed=$((installed + 1))
    else
        log_warning "Terraform: Not installed"
        missing=$((missing + 1))
    fi
    
    # Ansible
    if command_exists ansible; then
        log_success "Ansible: $(ansible --version 2>/dev/null | head -1 | awk '{print $3}' | tr -d '[]')"
        installed=$((installed + 1))
    else
        log_warning "Ansible: Not installed"
        missing=$((missing + 1))
    fi
    
    # Docker
    if command_exists docker && docker ps >/dev/null 2>&1; then
        log_success "Docker: $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
        installed=$((installed + 1))
    else
        log_warning "Docker: Not installed or not running"
        missing=$((missing + 1))
    fi
    
    # Git
    if command_exists git; then
        log_success "Git: $(git --version | awk '{print $3}')"
        installed=$((installed + 1))
    else
        log_warning "Git: Not installed"
        missing=$((missing + 1))
    fi
    
    echo ""
    log_info "Summary: $installed installed, $missing missing"
}

install_dependencies() {
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        log_error "Cannot detect operating system"
        exit 1
    fi
    
    log_info "Detected OS: $OS"
    
    case "$OS" in
        ubuntu|debian)
            install_deps_debian
            ;;
        *)
            log_warning "Automated installation not supported for $OS"
            log_info "Please install manually: az cli, terraform, ansible, docker, git"
            if ! confirm "Continue anyway?" "n"; then
                exit 1
            fi
            ;;
    esac
}

install_deps_debian() {
    log_info "Installing dependencies for Debian/Ubuntu..."
    
    # Update package list
    if confirm "Update package list (sudo apt update)?"; then
        sudo apt update
    fi
    
    # Azure CLI
    if ! command_exists az; then
        if confirm "Install Azure CLI?"; then
            log_info "Installing Azure CLI..."
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            log_success "Azure CLI installed"
        fi
    fi
    
    # Terraform
    if ! command_exists terraform; then
        if confirm "Install Terraform?"; then
            log_info "Installing Terraform..."
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install terraform -y
            log_success "Terraform installed"
        fi
    fi
    
    # Ansible
    if ! command_exists ansible; then
        if confirm "Install Ansible?"; then
            log_info "Installing Ansible..."
            sudo apt install -y python3-pip
            python3 -m pip install --user --break-system-packages ansible azure-cli-core azure-mgmt-compute azure-mgmt-network azure-mgmt-resource azure-identity msrestazure
            ansible-galaxy collection install azure.azcollection
            log_success "Ansible installed"
        fi
    fi
    
    # Docker
    if ! command_exists docker; then
        if confirm "Install Docker?"; then
            log_info "Installing Docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            log_success "Docker installed (logout/login required for group membership)"
        fi
    fi
    
    # Git
    if ! command_exists git; then
        if confirm "Install Git?"; then
            sudo apt install -y git
            log_success "Git installed"
        fi
    fi
}

configure_azure() {
    if ! command_exists az; then
        log_warning "Azure CLI not installed, skipping configuration"
        return
    fi
    
    # Check if logged in
    if ! az account show >/dev/null 2>&1; then
        log_info "Not logged into Azure CLI"
        if confirm "Login to Azure now?"; then
            az login
        else
            log_warning "Skipping Azure login (required for deployment)"
            return
        fi
    fi
    
    local current_account=$(az account show --query name -o tsv)
    log_success "Logged into Azure: $current_account"
    
    # Set subscription
    local expected_sub="6b9318b1-2215-418a-b0fd-ba0832e9b333"
    if confirm "Set default subscription to $expected_sub?"; then
        az account set --subscription "$expected_sub"
        log_success "Subscription set"
    fi
}

setup_terraform() {
    if ! command_exists terraform; then
        log_warning "Terraform not installed, skipping setup"
        return
    fi
    
    cd "${PROJECT_ROOT}/terraform"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        if confirm "Initialize Terraform?"; then
            terraform init
            log_success "Terraform initialized"
        fi
    else
        log_success "Terraform already initialized"
    fi
    
    # Create/select dev workspace
    if ! terraform workspace list | grep -q "dev"; then
        terraform workspace new dev
        log_success "Created dev workspace"
    else
        terraform workspace select dev
        log_success "Selected dev workspace"
    fi
    
    cd "${PROJECT_ROOT}"
}

setup_ansible() {
    if ! command_exists ansible; then
        log_warning "Ansible not installed, skipping setup"
        return
    fi
    
    # Verify Azure collection
    if ansible-galaxy collection list | grep -q "azure.azcollection"; then
        log_success "Ansible Azure collection installed"
    else
        log_info "Installing Ansible Azure collection..."
        ansible-galaxy collection install azure.azcollection
        log_success "Ansible Azure collection installed"
    fi
    
    # Verify Python Azure dependencies
    if python3 -c "import azure.mgmt.compute" 2>/dev/null; then
        log_success "Ansible Azure dependencies installed"
    else
        log_info "Installing Ansible Azure dependencies..."
        python3 -m pip install --user --break-system-packages \
            azure-cli-core azure-mgmt-compute azure-mgmt-network \
            azure-mgmt-resource azure-identity msrestazure
        log_success "Ansible Azure dependencies installed"
    fi
}

setup_ssh_keys() {
    local ssh_key="$HOME/.ssh/id_ed25519"
    
    if [ -f "$ssh_key" ]; then
        log_success "SSH key already exists: $ssh_key"
        return
    fi
    
    if confirm "Generate SSH key pair for VMSS access?"; then
        ssh-keygen -t ed25519 -f "$ssh_key" -C "terracloud-vmss"
        log_success "SSH key generated: $ssh_key"
        log_info "Public key:"
        cat "${ssh_key}.pub"
    fi
}

setup_local_config() {
    cd "${PROJECT_ROOT}"
    
    # Create .env.local if it doesn't exist
    if [ ! -f "config/.env.local" ]; then
        if confirm "Create config/.env.local from template?"; then
            cp config/secrets.template config/.env.local
            log_success "Created config/.env.local"
            log_warning "Edit config/.env.local and fill in your secrets!"
        fi
    else
        log_success "config/.env.local already exists"
    fi
    
    # Add to .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q ".env.local" .gitignore; then
            echo "config/.env.local" >> .gitignore
            log_success "Added .env.local to .gitignore"
        fi
    fi
}

verify_setup() {
    log_subheader "Running final verification..."
    
    local failed=0
    
    check_azure_cli || ((failed++))
    check_terraform || ((failed++))
    check_ansible || ((failed++))
    check_docker || ((failed++))
    check_git || ((failed++))
    
    echo ""
    
    if [ $failed -eq 0 ]; then
        log_success "All checks passed!"
        return 0
    else
        log_warning "$failed check(s) failed - some features may not work"
        return 1
    fi
}

# Run main function
main "$@"

