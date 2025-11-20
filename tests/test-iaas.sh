#!/bin/bash
# Test IaaS Deployment
# Usage: ./test-iaas.sh [environment]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/common/logging.sh"

ENVIRONMENT="${1:-dev}"

# Load environment config
if [ -f "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env" ]; then
    source "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env"
else
    log_error "Environment config not found: ${ENVIRONMENT}.env"
    exit 1
fi

main() {
    log_header "IaaS Tests - ${ENVIRONMENT}"
    
    local failed=0
    
    # Test 1: VMSS exists
    log_step "Test 1: VMSS exists"
    if test_vmss_exists; then
        log_success "VMSS exists"
    else
        log_error "VMSS not found"
        ((failed++))
    fi
    
    # Test 2: VMSS instances are running
    log_step "Test 2: VMSS instances are running"
    if test_vmss_running; then
        log_success "VMSS instances running"
    else
        log_error "VMSS instances not running"
        ((failed++))
    fi
    
    # Test 3: HTTP endpoint responds
    log_step "Test 3: HTTP endpoint responds"
    if test_http_endpoint; then
        log_success "HTTP endpoint OK"
    else
        log_error "HTTP endpoint failed"
        ((failed++))
    fi
    
    # Test 4: SSH connectivity
    log_step "Test 4: SSH connectivity"
    if test_ssh_connectivity; then
        log_success "SSH connectivity OK"
    else
        log_error "SSH connectivity failed"
        ((failed++))
    fi
    
    # Test 5: Docker is running
    log_step "Test 5: Docker is running on instances"
    if test_docker_running; then
        log_success "Docker is running"
    else
        log_error "Docker not running"
        ((failed++))
    fi
    
    # Test 6: Application container is running
    log_step "Test 6: Application container is running"
    if test_app_container_running; then
        log_success "Application container running"
    else
        log_error "Application container not running"
        ((failed++))
    fi
    
    # Summary
    echo ""
    log_header "Test Summary"
    
    local total=6
    local passed=$((total - failed))
    
    echo "Passed: ${passed}/${total}"
    echo "Failed: ${failed}/${total}"
    
    if [ $failed -eq 0 ]; then
        log_success "All tests passed!"
        return 0
    else
        log_error "${failed} test(s) failed"
        return 1
    fi
}

test_vmss_exists() {
    az vmss show \
        --name "${VMSS_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        >/dev/null 2>&1
}

test_vmss_running() {
    local running=$(az vmss list-instances \
        --name "${VMSS_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "[?provisioningState=='Succeeded'].name" -o tsv 2>/dev/null | wc -l)
    
    log_info "Running instances: ${running}"
    
    [ "$running" -gt 0 ]
}

test_http_endpoint() {
    local first_ip=$(az vmss list-instance-public-ips \
        --name "${VMSS_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "[0].ipAddress" -o tsv 2>/dev/null)
    
    if [ -z "$first_ip" ]; then
        log_warning "No public IP found"
        return 1
    fi
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://${first_ip}" 2>/dev/null || echo "000")
    
    log_info "HTTP Status: ${http_code} (IP: ${first_ip})"
    
    [ "$http_code" = "200" ]
}

test_ssh_connectivity() {
    cd "${PROJECT_ROOT}/ansible"
    
    if [ ! -f "inventory/static.yml" ]; then
        log_warning "Static inventory not found"
        return 1
    fi
    
    ansible all -i inventory/static.yml -m ping -o >/dev/null 2>&1
}

test_docker_running() {
    cd "${PROJECT_ROOT}/ansible"
    
    if [ ! -f "inventory/static.yml" ]; then
        return 1
    fi
    
    ansible all -i inventory/static.yml -m shell -a 'docker ps' -b >/dev/null 2>&1
}

test_app_container_running() {
    cd "${PROJECT_ROOT}/ansible"
    
    if [ ! -f "inventory/static.yml" ]; then
        return 1
    fi
    
    ansible all -i inventory/static.yml -m shell -a 'docker ps | grep laravel-app' -b >/dev/null 2>&1
}

main "$@"

