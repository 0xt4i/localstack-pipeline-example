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
echo -e "${GREEN}  LocalStack Terraform Deployment${NC}"
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

# Check if LocalStack is running
check_localstack() {
    log_info "Checking LocalStack status..."
    if ! curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        log_error "LocalStack is not running!"
        log_info "Please start LocalStack first:"
        echo "  source localstack/bin/activate"
        echo "  localstack start -d"
        exit 1
    fi
    log_info "LocalStack is running ✓"
}

# Check if k3d is installed
check_k3d() {
    log_info "Checking k3d installation..."
    if ! command -v k3d &> /dev/null; then
        log_warn "k3d is not installed. EKS cluster creation may fail."
        log_info "Install k3d with: wget -q -O ~/bin/k3d https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-amd64 && chmod +x ~/bin/k3d"
    else
        log_info "k3d is installed ✓"
    fi
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
            echo "  --auto-approve         Auto approve terraform apply"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Deploy dev environment"
            echo "  $0 -e prod                  # Deploy prod environment"
            echo "  $0 --auto-approve           # Deploy with auto-approve"
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

# Check prerequisites
check_localstack
check_k3d

log_info "Applying Terraform configuration..."

# First create VPC
log_info "Step 1/2: Creating VPC infrastructure..."
terraform apply \
    -var-file=env/common.tfvars \
    -var-file=env/${ENVIRONMENT}.tfvars \
    -target=module.vpc \
    $AUTO_APPROVE

# Then create EKS (if not auto-approve, ask user)
if [ -z "$AUTO_APPROVE" ]; then
    echo ""
    read -p "Do you want to create EKS cluster? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping EKS cluster creation"
        exit 0
    fi
fi

log_info "Step 2/2: Creating EKS cluster (this may take 3-5 minutes)..."
terraform apply \
    -var-file=env/common.tfvars \
    -var-file=env/${ENVIRONMENT}.tfvars \
    $AUTO_APPROVE

# Success message
if [ $? -eq 0 ]; then
    echo ""
    log_info "Terraform deployment completed successfully! ✓"
    echo ""
    log_info "Next steps:"
    echo "  - Check resources: terraform show"
    echo "  - Get outputs: terraform output"
    echo "  - Verify EKS: aws eks describe-cluster --name project_1-${ENVIRONMENT}-eks --endpoint-url=http://localhost:4566"
else
    log_error "Terraform deployment failed!"
    exit 1
fi
