#!/bin/bash
# Test PaaS Deployment
# Usage: ./test-paas.sh [environment]

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
    log_header "PaaS Tests - ${ENVIRONMENT}"
    
    local failed=0
    
    # Test 1: App Service exists
    log_step "Test 1: App Service exists"
    if test_app_service_exists; then
        log_success "App Service exists"
    else
        log_error "App Service not found"
        ((failed++))
    fi
    
    # Test 2: App Service is running
    log_step "Test 2: App Service is running"
    if test_app_service_running; then
        log_success "App Service is running"
    else
        log_error "App Service is not running"
        ((failed++))
    fi
    
    # Test 3: App Service responds to HTTP
    log_step "Test 3: HTTP endpoint responds"
    if test_http_endpoint; then
        log_success "HTTP endpoint OK"
    else
        log_error "HTTP endpoint failed"
        ((failed++))
    fi
    
    # Test 4: MySQL is accessible
    log_step "Test 4: MySQL server is accessible"
    if test_mysql_accessible; then
        log_success "MySQL is accessible"
    else
        log_error "MySQL is not accessible"
        ((failed++))
    fi
    
    # Test 5: ACR is accessible
    log_step "Test 5: ACR is accessible"
    if test_acr_accessible; then
        log_success "ACR is accessible"
    else
        log_error "ACR is not accessible"
        ((failed++))
    fi
    
    # Summary
    echo ""
    log_header "Test Summary"
    
    local total=5
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

test_app_service_exists() {
    az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        >/dev/null 2>&1
}

test_app_service_running() {
    local state=$(az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "state" -o tsv 2>/dev/null)
    
    [ "$state" = "Running" ]
}

test_http_endpoint() {
    local url=$(az webapp show \
        --name "${APP_SERVICE_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "defaultHostName" -o tsv 2>/dev/null)
    
    if [ -z "$url" ]; then
        return 1
    fi
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://${url}" 2>/dev/null || echo "000")
    
    log_info "HTTP Status: ${http_code}"
    
    [ "$http_code" = "200" ]
}

test_mysql_accessible() {
    az mysql flexible-server show \
        --name "${MYSQL_SERVER_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "state" -o tsv 2>/dev/null | grep -q "Ready"
}

test_acr_accessible() {
    az acr show \
        --name "${ACR_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        >/dev/null 2>&1
}

main "$@"

