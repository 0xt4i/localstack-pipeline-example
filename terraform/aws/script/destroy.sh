#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  LocalStack Terraform Destroy${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to print messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
ENVIRONMENT="dev"
AUTO_APPROVE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --auto-approve)
            AUTO_APPROVE="-auto-approve"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --env ENV          Environment (dev|prod) [default: dev]"
            echo "  --auto-approve         Auto approve terraform destroy"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Destroy dev environment"
            echo "  $0 -e prod                      # Destroy prod environment"
            echo "  $0 --auto-approve               # Destroy dev with auto-approve"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT (must be dev or prod)"
    exit 1
fi

# Change to terraform directory
cd "$TERRAFORM_DIR"

log_info "Environment: $ENVIRONMENT"
log_info "Working directory: $TERRAFORM_DIR"
echo ""

# Warn user
log_warn "This will DESTROY all infrastructure in $ENVIRONMENT!"
log_warn "State files will also be removed!"

if [ -z "$AUTO_APPROVE" ]; then
    echo ""
    read -p "Are you sure you want to continue? (yes/no) " confirmation
    if [[ ! "$confirmation" == "yes" ]]; then
        log_info "Destroy cancelled"
        exit 0
    fi
    echo ""
fi

# Clean up old Terraform state
log_info "Cleaning up old Terraform state..."
rm -rf .terraform .terraform.lock.hcl terraform.tfstate* 2>/dev/null || true

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init

# Run destroy
log_info "Running terraform destroy..."
terraform destroy \
    -var-file=env/common.tfvars \
    -var-file=env/${ENVIRONMENT}.tfvars \
    $AUTO_APPROVE

if [ $? -eq 0 ]; then
    log_info "Cleaning up Terraform state files..."
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate* 2>/dev/null || true
    
    echo ""
    log_info "Terraform destroy completed successfully! ✓"
    log_info "All state files have been removed ✓"
else
    log_error "Terraform destroy failed!"
    exit 1
fi
