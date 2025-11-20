#!/bin/bash
# Test HTTPS/SSL Configuration
# Usage: ./test-https.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/common/logging.sh"

DOMAIN="epi-clo.axel-martin.fr"

main() {
    log_header "HTTPS/SSL Tests"
    
    local failed=0
    
    # Test 1: Domain resolves
    log_step "Test 1: Domain DNS resolution"
    if test_dns_resolution; then
        log_success "Domain resolves"
    else
        log_error "Domain does not resolve"
        ((failed++))
    fi
    
    # Test 2: HTTPS endpoint responds
    log_step "Test 2: HTTPS endpoint responds"
    if test_https_endpoint; then
        log_success "HTTPS endpoint OK"
    else
        log_error "HTTPS endpoint failed"
        ((failed++))
    fi
    
    # Test 3: SSL certificate is valid
    log_step "Test 3: SSL certificate validity"
    if test_ssl_certificate; then
        log_success "SSL certificate is valid"
    else
        log_error "SSL certificate invalid"
        ((failed++))
    fi
    
    # Test 4: HTTP redirects to HTTPS
    log_step "Test 4: HTTP to HTTPS redirect"
    if test_http_redirect; then
        log_success "HTTP redirects to HTTPS"
    else
        log_error "HTTP redirect failed"
        ((failed++))
    fi
    
    # Test 5: SSL Labs grade (optional)
    log_step "Test 5: SSL configuration quality"
    test_ssl_quality || log_warning "SSL quality check skipped"
    
    # Summary
    echo ""
    log_header "Test Summary"
    
    local total=4
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

test_dns_resolution() {
    local ip=$(dig +short "${DOMAIN}" | head -1)
    
    if [ -n "$ip" ]; then
        log_info "Domain resolves to: ${ip}"
        return 0
    else
        return 1
    fi
}

test_https_endpoint() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}" 2>/dev/null || echo "000")
    
    log_info "HTTP Status: ${http_code}"
    
    [ "$http_code" = "200" ]
}

test_ssl_certificate() {
    local cert_info=$(echo | openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
    
    if [ -n "$cert_info" ]; then
        log_info "Certificate info:"
        echo "$cert_info" | while read line; do
            log_info "  $line"
        done
        
        # Check if certificate is not expired
        local expiry=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo "0")
        local now_epoch=$(date +%s)
        
        if [ "$expiry_epoch" -gt "$now_epoch" ]; then
            local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
            log_info "Certificate valid for ${days_left} more days"
            return 0
        else
            log_error "Certificate expired!"
            return 1
        fi
    else
        return 1
    fi
}

test_http_redirect() {
    local redirect=$(curl -s -o /dev/null -w "%{redirect_url}" "http://${DOMAIN}" 2>/dev/null || echo "")
    
    if echo "$redirect" | grep -q "https://"; then
        log_info "Redirects to: ${redirect}"
        return 0
    else
        return 1
    fi
}

test_ssl_quality() {
    log_info "For detailed SSL analysis, visit:"
    echo "  https://www.ssllabs.com/ssltest/analyze.html?d=${DOMAIN}"
    
    # Check for common issues
    local ciphers=$(echo | openssl s_client -cipher 'NULL,EXPORT,LOW,DES' -connect "${DOMAIN}:443" 2>&1)
    
    if echo "$ciphers" | grep -q "Cipher is"; then
        log_warning "Weak ciphers may be enabled"
    else
        log_info "No weak ciphers detected"
    fi
    
    return 0
}

main "$@"

