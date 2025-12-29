#!/bin/bash

set -e  # Exit on error

# Script directory (project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_SCRIPT="$PROJECT_ROOT/terraform/aws/script/deploy.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  LocalStack CI/CD Pipeline Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
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
        echo ""
        log_info "Starting LocalStack..."
        echo "  cd $PROJECT_ROOT"
        echo "  source localstack/bin/activate"
        echo "  localstack start -d"
        echo ""
        read -p "Do you want to start LocalStack now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$PROJECT_ROOT"
            if [ -d "localstack/bin" ]; then
                source localstack/bin/activate
                localstack start -d
                log_info "Waiting for LocalStack to be ready..."
                sleep 5
            else
                log_error "LocalStack venv not found. Please run: python3 -m venv localstack && source localstack/bin/activate && pip install localstack"
                exit 1
            fi
        else
            exit 1
        fi
    fi
    log_info "LocalStack is running ✓"
}

# Check Docker Compose services
check_services() {
    log_info "Checking Docker Compose services..."

    cd "$PROJECT_ROOT"

    # Check if Jenkins is running
    if docker ps | grep -q jenkins-jdk-17; then
        log_info "Jenkins is running ✓"
    else
        log_warn "Jenkins is not running"
        read -p "Do you want to start Jenkins and Ansible? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Starting Jenkins and Ansible..."
            docker-compose up -d jenkins ansible
            log_info "Services started ✓"
        fi
    fi
}

# Run all deployment steps
run_all() {
    local env=$1
    local auto_approve=$2

    log_info "Running complete deployment pipeline for environment: $env"
    echo ""

    # Step 1: Initialize Terraform
    log_info "Step 1/3: Initializing Terraform..."
    bash "$TERRAFORM_SCRIPT" -e "$env" -a init
    echo ""

    # Step 2: Plan
    log_info "Step 2/3: Planning deployment..."
    bash "$TERRAFORM_SCRIPT" -e "$env" -a plan
    echo ""

    # Step 3: Apply
    if [ -n "$auto_approve" ]; then
        log_info "Step 3/3: Applying infrastructure (auto-approved)..."
        bash "$TERRAFORM_SCRIPT" -e "$env" -a apply --auto-approve
    else
        log_info "Step 3/3: Applying infrastructure..."
        bash "$TERRAFORM_SCRIPT" -e "$env" -a apply
    fi
}

# Show help
show_help() {
    cat << EOF
Usage: $0 [ENVIRONMENT] [ACTION] [OPTIONS]

This script deploys infrastructure to LocalStack using Terraform.

POSITIONAL ARGUMENTS:
  ENVIRONMENT            Environment (dev|prod) [default: dev]
  ACTION                 Action to perform:
                           - all: Run init + plan + apply (complete pipeline)
                           - init: Initialize Terraform
                           - plan: Show deployment plan
                           - apply: Deploy infrastructure
                           - destroy: Destroy infrastructure
                           - validate: Validate Terraform config
                         [default: apply]

OPTIONS:
  --auto-approve         Auto approve terraform apply/destroy
  --skip-checks          Skip LocalStack and Docker checks
  -h, --help             Show this help message

EXAMPLES:
  # Run complete deployment for dev (init + plan + apply)
  $0 dev all

  # Run complete deployment with auto-approve
  $0 dev all --auto-approve

  # Plan prod environment
  $0 prod plan

  # Deploy dev with auto-approve
  $0 dev apply --auto-approve

  # Destroy dev environment
  $0 dev destroy --auto-approve

  # Just validate configuration
  $0 dev validate --skip-checks

  # Legacy format still works
  $0 -e prod -a plan

WORKFLOW (when using 'all'):
  1. Check LocalStack is running
  2. Check Docker services (Jenkins, Ansible)
  3. Initialize Terraform
  4. Plan deployment
  5. Apply infrastructure
  6. Show next steps

EOF
}

# Parse arguments
SKIP_CHECKS=false
ENVIRONMENT=""
ACTION=""
AUTO_APPROVE=""
LEGACY_MODE=false

# First pass: check for flags and positional arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE="--auto-approve"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--env)
            LEGACY_MODE=true
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            LEGACY_MODE=true
            ACTION="$2"
            shift 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Parse positional arguments if not using legacy mode
if [ "$LEGACY_MODE" = false ]; then
    if [ ${#POSITIONAL[@]} -ge 1 ]; then
        ENVIRONMENT="${POSITIONAL[0]}"
    fi
    if [ ${#POSITIONAL[@]} -ge 2 ]; then
        ACTION="${POSITIONAL[1]}"
    fi
fi

# Set defaults
ENVIRONMENT="${ENVIRONMENT:-dev}"
ACTION="${ACTION:-apply}"

# Perform checks unless skipped
if [ "$SKIP_CHECKS" = false ]; then
    check_localstack
    check_services
    echo ""
fi

# Handle 'all' action specially
if [ "$ACTION" == "all" ]; then
    run_all "$ENVIRONMENT" "$AUTO_APPROVE"
else
    # Run Terraform deployment script
    log_info "Running Terraform deployment script..."
    echo ""

    if [ -f "$TERRAFORM_SCRIPT" ]; then
        bash "$TERRAFORM_SCRIPT" -e "$ENVIRONMENT" -a "$ACTION" $AUTO_APPROVE
    else
        log_error "Terraform deployment script not found: $TERRAFORM_SCRIPT"
        exit 1
    fi
fi

# Show completion message and next steps
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deployment Completed Successfully! ✓${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    log_info "Infrastructure deployed to LocalStack"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  📊 View Terraform state:    cd terraform/aws && terraform show"
    echo "  📋 Get outputs:             cd terraform/aws && terraform output"
    echo "  🔍 Check LocalStack:        curl http://localhost:4566/_localstack/health"
    echo "  🌐 Access Jenkins:          http://localhost:8080"
    echo "  📡 List EKS clusters:       aws eks list-clusters --endpoint-url=http://localhost:4566"
    echo ""
else
    log_error "Deployment failed! Please check the error messages above."
    exit 1
fi
