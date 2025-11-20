#!/bin/bash
# Build and Push Docker Image to ACR
# Usage: ./build-push-image.sh [environment] [tag]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source utilities
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/checks.sh"

# Configuration
ENVIRONMENT="${1:-dev}"
CUSTOM_TAG="${2:-}"
APP_DIR="${PROJECT_ROOT}/sample-app-master"

# Load environment config
if [ -f "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env" ]; then
    source "${PROJECT_ROOT}/config/environments/${ENVIRONMENT}.env"
else
    log_error "Environment config not found: ${ENVIRONMENT}.env"
    exit 1
fi

# Generate version tag
generate_version_tag() {
    local git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
    local timestamp=$(date +%Y%m%d-%H%M%S)
    echo "${git_sha}-${timestamp}"
}

# Main function
main() {
    log_header "Docker Image Build & Push"
    
    log_info "Environment: ${ENVIRONMENT}"
    log_info "ACR: ${ACR_LOGIN_SERVER}"
    log_info "Image: ${DOCKER_IMAGE_NAME}"
    echo ""
    
    # Check prerequisites
    log_step "Step 1: Checking prerequisites"
    if ! check_docker; then
        log_error "Docker check failed"
        exit 1
    fi
    
    if ! check_azure_cli; then
        log_error "Azure CLI check failed"
        exit 1
    fi
    
    # Login to ACR
    log_step "Step 2: Logging into Azure Container Registry"
    login_to_acr
    
    # Determine tags
    log_step "Step 3: Determining image tags"
    local version_tag=$(generate_version_tag)
    local tags=("latest" "$version_tag")
    
    if [ -n "$CUSTOM_TAG" ]; then
        tags+=("$CUSTOM_TAG")
    fi
    
    log_info "Tags that will be applied:"
    for tag in "${tags[@]}"; do
        echo "  - ${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${tag}"
    done
    echo ""
    
    if ! confirm "Continue with build and push?" "y"; then
        log_info "Operation cancelled"
        exit 0
    fi
    
    # Build image
    log_step "Step 4: Building Docker image"
    build_image "$version_tag"
    
    # Tag images
    log_step "Step 5: Tagging images"
    tag_images "$version_tag" "${tags[@]}"
    
    # Test image (optional)
    log_step "Step 6: Testing image (optional)"
    if confirm "Run basic image test?" "n"; then
        test_image "$version_tag"
    else
        log_info "Skipping image test"
    fi
    
    # Push to ACR
    log_step "Step 7: Pushing images to ACR"
    push_images "${tags[@]}"
    
    # List available tags
    log_step "Step 8: Listing available tags in ACR"
    list_acr_tags
    
    # Summary
    log_header "Build & Push Complete!"
    log_success "Image successfully pushed to ${ACR_LOGIN_SERVER}"
    echo ""
    log_info "Available tags:"
    for tag in "${tags[@]}"; do
        echo "  - ${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${tag}"
    done
    echo ""
    log_info "Next steps:"
    echo "  - Deploy to PaaS: make deploy-paas ENV=${ENVIRONMENT}"
    echo "  - Deploy to IaaS: make deploy-iaas ENV=${ENVIRONMENT}"
    echo ""
}

login_to_acr() {
    log_info "Logging into ${ACR_NAME}..."
    
    if az acr login --name "${ACR_NAME}" 2>&1 | grep -q "Login Succeeded"; then
        log_success "Successfully logged into ACR"
    else
        log_error "Failed to login to ACR"
        log_info "Make sure you have permissions: az role assignment create --role AcrPull --scope /subscriptions/.../resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}"
        exit 1
    fi
}

build_image() {
    local version_tag=$1
    
    cd "${APP_DIR}"
    
    log_info "Building image: ${DOCKER_IMAGE_NAME}:${version_tag}"
    log_info "Build context: ${APP_DIR}"
    echo ""
    
    # Build with progress output
    if docker build \
        --tag "${DOCKER_IMAGE_NAME}:${version_tag}" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
        . ; then
        log_success "Image built successfully"
    else
        log_error "Image build failed"
        exit 1
    fi
    
    cd "${PROJECT_ROOT}"
}

tag_images() {
    local version_tag=$1
    shift
    local tags=("$@")
    
    for tag in "${tags[@]}"; do
        if [ "$tag" != "$version_tag" ]; then
            log_info "Tagging: ${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${tag}"
            docker tag \
                "${DOCKER_IMAGE_NAME}:${version_tag}" \
                "${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${tag}"
        else
            log_info "Tagging: ${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${version_tag}"
            docker tag \
                "${DOCKER_IMAGE_NAME}:${version_tag}" \
                "${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${version_tag}"
        fi
    done
    
    log_success "All tags applied"
}

test_image() {
    local version_tag=$1
    
    log_info "Running basic container test..."
    
    # Try to start container
    local container_id=$(docker run -d --rm \
        -e DB_CONNECTION=sqlite \
        -e DB_DATABASE=:memory: \
        "${DOCKER_IMAGE_NAME}:${version_tag}" 2>&1)
    
    if [ $? -eq 0 ]; then
        log_success "Container started successfully"
        sleep 3
        
        # Check if still running
        if docker ps | grep -q "$container_id"; then
            log_success "Container is healthy"
            docker stop "$container_id" >/dev/null 2>&1 || true
        else
            log_warning "Container stopped unexpectedly"
            docker logs "$container_id" 2>&1 | tail -20
        fi
    else
        log_warning "Container test failed (non-critical)"
    fi
}

push_images() {
    local tags=("$@")
    local total=${#tags[@]}
    local current=0
    
    for tag in "${tags[@]}"; do
        current=$((current + 1))
        log_info "Pushing [${current}/${total}]: ${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${tag}"
        
        if docker push "${ACR_LOGIN_SERVER}/${DOCKER_IMAGE_NAME}:${tag}"; then
            log_success "Pushed: ${tag}"
        else
            log_error "Failed to push: ${tag}"
            exit 1
        fi
    done
    
    log_success "All images pushed successfully"
}

list_acr_tags() {
    log_info "Available tags in ACR:"
    
    if az acr repository show-tags \
        --name "${ACR_NAME}" \
        --repository "${DOCKER_IMAGE_NAME}" \
        --output table 2>/dev/null; then
        log_success "Tags listed"
    else
        log_warning "Could not list tags (repository may be empty)"
    fi
}

# Cleanup on exit
cleanup() {
    log_info "Cleaning up..."
    # Remove untagged local images if needed
}

trap cleanup EXIT

# Run main function
main "$@"

