#!/bin/bash
# Test Database Connectivity
# Usage: ./test-database.sh [environment]

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

# Load secrets
if [ -f "${PROJECT_ROOT}/config/.env.local" ]; then
    source "${PROJECT_ROOT}/config/.env.local"
fi

main() {
    log_header "Database Tests - ${ENVIRONMENT}"
    
    local failed=0
    
    # Test 1: MySQL server exists
    log_step "Test 1: MySQL server exists"
    if test_mysql_exists; then
        log_success "MySQL server exists"
    else
        log_error "MySQL server not found"
        ((failed++))
    fi
    
    # Test 2: MySQL server is ready
    log_step "Test 2: MySQL server is ready"
    if test_mysql_ready; then
        log_success "MySQL server is ready"
    else
        log_error "MySQL server is not ready"
        ((failed++))
    fi
    
    # Test 3: Firewall rules configured
    log_step "Test 3: Firewall rules configured"
    if test_firewall_rules; then
        log_success "Firewall rules OK"
    else
        log_warning "Firewall rules may need review"
    fi
    
    # Test 4: Database exists
    log_step "Test 4: Application database exists"
    test_database_exists || log_warning "Database check skipped (requires mysql client)"
    
    # Summary
    echo ""
    log_header "Test Summary"
    
    local total=2  # Only count critical tests
    local passed=$((total - failed))
    
    echo "Passed: ${passed}/${total}"
    echo "Failed: ${failed}/${total}"
    
    if [ $failed -eq 0 ]; then
        log_success "All critical tests passed!"
        return 0
    else
        log_error "${failed} test(s) failed"
        return 1
    fi
}

test_mysql_exists() {
    az mysql flexible-server show \
        --name "${MYSQL_SERVER_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        >/dev/null 2>&1
}

test_mysql_ready() {
    local state=$(az mysql flexible-server show \
        --name "${MYSQL_SERVER_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "state" -o tsv 2>/dev/null)
    
    log_info "MySQL State: ${state}"
    
    [ "$state" = "Ready" ]
}

test_firewall_rules() {
    local rules=$(az mysql flexible-server firewall-rule list \
        --name "${MYSQL_SERVER_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --query "[].name" -o tsv 2>/dev/null)
    
    if [ -n "$rules" ]; then
        log_info "Firewall rules configured:"
        echo "$rules" | while read rule; do
            log_info "  - $rule"
        done
        return 0
    else
        log_warning "No firewall rules found"
        return 1
    fi
}

test_database_exists() {
    if ! command -v mysql >/dev/null 2>&1; then
        log_warning "mysql client not installed, skipping database test"
        return 0
    fi
    
    if [ -z "${MYSQL_ADMIN_PASSWORD:-}" ]; then
        log_warning "MYSQL_ADMIN_PASSWORD not set, skipping database test"
        return 0
    fi
    
    log_info "Testing database connection..."
    
    mysql -h "${MYSQL_SERVER_NAME}.mysql.database.azure.com" \
        -u "${MYSQL_USERNAME}" \
        -p"${MYSQL_ADMIN_PASSWORD}" \
        -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" \
        2>/dev/null | grep -q "${MYSQL_DATABASE}"
    
    if [ $? -eq 0 ]; then
        log_success "Database '${MYSQL_DATABASE}' exists"
        return 0
    else
        log_warning "Could not verify database existence"
        return 1
    fi
}

main "$@"

