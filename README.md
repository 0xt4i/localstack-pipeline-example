### 4. Lỗi treo khi tạo node EKS với Terraform (LocalStack)

**Vấn đề**: Khi sử dụng resource `aws_instance` (EC2) để tạo worker node cho EKS trong LocalStack, quá trình apply sẽ bị treo mãi ở bước tạo instance (do LocalStack chỉ mô phỏng API EC2, không tạo VM thật).

**Triệu chứng**:
```
module.eks_nodes.aws_instance.worker_nodes[0]: Still creating... [05m30s elapsed]
module.eks_nodes.aws_instance.ansible_controller: Still creating... [05m40s elapsed]
... (tiếp tục treo)
```

**Nguyên nhân**: LocalStack không hỗ trợ tạo EC2 instance thật, chỉ mô phỏng API. Terraform sẽ chờ mãi không xong.

**Giải pháp**:
- Không sử dụng resource `aws_instance` cho worker node khi chạy với LocalStack.
- Thay vào đó, chỉ sử dụng resource `aws_eks_node_group` để mô phỏng nodegroup (giống như dùng lệnh `awslocal eks create-nodegroup`).
- Nếu module cũ có aws_instance, hãy comment/xóa các resource này để tránh treo apply/destroy.

**Tham khảo thêm**: Xem phần hướng dẫn sửa module EKS trong README này.
# 🌐 LocalStack CI/CD Pipeline với Terraform, Jenkins và Ansible

Một hệ thống hạ tầng CI/CD hoàn chỉnh sử dụng **LocalStack** để mô phỏng môi trường AWS. Dự án này sử dụng **Terraform** để khởi tạo hạ tầng AWS (VPC, EKS), **Jenkins** cho continuous integration, và **Ansible** cho automation và configuration management.

> **Lưu ý**: Đây là môi trường **học tập và phát triển** sử dụng LocalStack để mô phỏng các dịch vụ AWS mà không phát sinh chi phí.

---

## 📐 Kiến trúc Dự án

![Architecture](https://github.com/user-attachments/assets/4881fd5d-7aa4-48e7-b55a-3f19b24b112d)

---

## 🏗️ Tổng quan Kiến trúc

### 1. ☁️ Hạ tầng AWS (Được mô phỏng bởi LocalStack)

- **LocalStack Pro**:
  - Mô phỏng các dịch vụ AWS: VPC, EC2, EKS, S3, ECR, SNS, SES, IAM
  - Chạy trên cổng 4566 (Gateway)
  - Hỗ trợ Terraform để provision resources
  - **EKS với k3d backend**: Tạo Kubernetes cluster thật chạy bên trong Docker

- **Jenkins Container**:
  - Jenkins Master để điều phối CI pipeline
  - Thực thi các jobs: build, test, scan, deploy

- **Ansible Container**:
  - Automation và configuration management
  - Deploy resources lên LocalStack/AWS
  - Quản lý infrastructure state

### 2. 🔧 Các dịch vụ AWS được mô phỏng

- **VPC**: Virtual Private Cloud với public/private subnets
- **EKS**: Kubernetes cluster (sử dụng k3d backend)
- **S3**: Lưu trữ Terraform state, artifacts
- **ECR**: Container registry để lưu Docker images
- **SNS/SES**: Gửi thông báo email
- **IAM**: Quản lý permissions và roles

---

## ✅ Yêu cầu Tiên quyết

- **Docker & Docker Compose** đã cài đặt ([Hướng dẫn cài đặt](https://docs.docker.com/get-docker/))
- **Git** đã cài đặt ([Download Git](https://git-scm.com/downloads))
- **Python 3.8+** cho LocalStack CLI ([Download Python](https://www.python.org/downloads/))
- **k3d v5.8.3** (cho EKS cluster support) ([Cài đặt k3d](https://k3d.io/#installation))
- **Terraform CLI v1.0+** ([Download Terraform](https://developer.hashicorp.com/terraform/install))
- **LocalStack Pro Auth Token** (cho EKS và các Pro features) - Đăng ký tại [app.localstack.cloud](https://app.localstack.cloud)
- **AWS CLI** (để tương tác với LocalStack) ([Cài đặt AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))

### Cài đặt k3d

```bash
# Linux
wget -q -O /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-amd64
chmod +x /usr/local/bin/k3d

# Verify
k3d version
```

---

## 📁 Cấu trúc Dự án

```bash
.
├── deploy.sh                     # Script deployment chính (wrapper)
├── start-localstack.sh           # Script khởi động LocalStack với k3d support
├── docker-compose.yaml           # Docker Compose: Jenkins, Ansible
├── jenkins/                      # Jenkins docker setup
│   ├── Dockerfile                # Custom Jenkins image với tools
│   └── ...
├── ansible/                      # Ansible automation
│   ├── Dockerfile                # Ansible controller image
│   ├── ansible.cfg               # Ansible configuration
│   ├── playbooks/                # Ansible playbooks
│   ├── inventory/                # Inventory files
│   └── roles/                    # Ansible roles
├── terraform/                    # Terraform infrastructure
│   └── aws/
│       ├── main.tf               # Main Terraform config
│       ├── providers.tf          # AWS provider config (LocalStack endpoints)
│       ├── variables.tf          # Input variables
│       ├── outputs.tf            # Output values
│       ├── modules/
│       │   ├── vpc/              # VPC module
│       │   └── eks/              # EKS module
│       ├── env/
│       │   ├── common.tfvars     # Common variables
│       │   ├── dev.tfvars        # Dev environment
│       │   └── prod.tfvars       # Prod environment
│       └── script/
│           └── deploy.sh         # Terraform deployment script
└── README.md                     # File documentation chính
```

---

## 🚀 Hướng dẫn Triển khai Nhanh

### Bước 1: Cấu hình Environment Variables

```bash
# Set LocalStack auth token (lấy từ https://app.localstack.cloud)
export LOCALSTACK_AUTH_TOKEN=your-token-here

# Tùy chọn: Enable persistence
export PERSISTENCE=0
export DEBUG=0
```

### Bước 2: Khởi động tất cả services với Docker Compose

```bash
# Start LocalStack, Jenkins, Ansible
docker-compose up -d

# Kiểm tra containers
docker-compose ps

# Xem logs
docker logs -f localstack-main
```

Docker Compose sẽ tự động:
- ✅ Tạo shared network `localstack-net` (bridge driver)
- ✅ Khởi động LocalStack Pro trên port 4566
- ✅ Khởi động Jenkins trên port 8080
- ✅ Khởi động Ansible controller
- ✅ Cấu hình DNS resolution giữa các services (localstack, jenkins, ansible)

**Lưu ý quan trọng**:
- LocalStack container có k3d binary được mount [text](volume/lib)qua Docker socket
- Tất cả services giao tiếp qua shared network `localstack-net`
- Jenkins và Ansible truy cập LocalStack qua `http://localstack:4566`

### Bước 3: Verify Services

```bash
# Kiểm tra LocalStack health
curl http://localhost:4566/_localstack/health

# Truy cập Jenkins UI
open http://localhost:8080  # Lấy initial admin password từ: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Test kết nối từ Jenkins đến LocalStack
docker exec jenkins curl http://localstack:4566/_localstack/health

# Test kết nối từ Ansible đến LocalStack
docker exec ansible curl http://localstack:4566/_localstack/health
```

### Bước 4: Deploy Infrastructure với Terraform

**Cách 1: Sử dụng script deploy.sh (Khuyến nghị)**

```bash
# Deploy hoàn chỉnh (init + plan + apply)
./deploy.sh dev all

# Deploy với auto-approve (không cần xác nhận)
./deploy.sh dev all --auto-approve

# Chỉ plan
./deploy.sh dev plan

# Chỉ apply
./deploy.sh dev apply

# Destroy infrastructure
./deploy.sh dev destroy --auto-approve
```

**Cách 2: Sử dụng Terraform trực tiếp**

```bash
cd terraform/aws

# Initialize
terraform init

# Plan
terraform plan \
  -var-file=env/common.tfvars \
  -var-file=env/dev.tfvars

# Apply (tạo VPC trước)
terraform apply \
  -var-file=env/common.tfvars \
  -var-file=env/dev.tfvars \
  -target=module.vpc

# Apply (tạo EKS cluster - mất 3-5 phút)
terraform apply \
  -var-file=env/common.tfvars \
  -var-file=env/dev.tfvars
```

### Bước 5: Verify Infrastructure

```bash
# List VPC
aws ec2 describe-vpcs --endpoint-url=http://localhost:4566

# List EKS clusters
aws eks list-clusters --endpoint-url=http://localhost:4566 --region ap-southeast-1

# Describe EKS cluster
aws eks describe-cluster \
  --name project_1-dev-eks \
  --endpoint-url=http://localhost:4566 \
  --region ap-southeast-1

# List k3d clusters (nếu EKS đã tạo)
k3d cluster list

# Lấy kubeconfig và verify
aws eks update-kubeconfig \
  --name project_1-dev-eks \
  --endpoint-url=http://localhost:4566 \
  --region ap-southeast-1

kubectl get nodes
```

---

## 🛠️ Các Scripts Tiện ích

### deploy.sh - Main Deployment Script

Script wrapper chính để deploy infrastructure:

```bash
# Syntax
./deploy.sh [ENVIRONMENT] [ACTION] [OPTIONS]

# Examples
./deploy.sh dev all                    # Deploy dev environment (init + plan + apply)
./deploy.sh dev all --auto-approve     # Deploy dev với auto-approve
./deploy.sh prod plan                  # Plan prod environment
./deploy.sh dev apply --auto-approve   # Apply dev changes
./deploy.sh dev destroy --auto-approve # Destroy dev infrastructure
./deploy.sh dev validate --skip-checks # Validate config only
```

**Tính năng:**
- ✅ Kiểm tra LocalStack đang chạy (qua Docker Compose)
- ✅ Kiểm tra Docker services (Jenkins, Ansible)
- ✅ Hỗ trợ command `all` để chạy pipeline hoàn chỉnh
- ✅ Auto-approve mode
- ✅ Skip checks mode

### start-localstack.sh - Legacy Script (Tùy chọn)

Script khởi động LocalStack CLI (alternative approach):

```bash
./start-localstack.sh
```

**Lưu ý**: Script này dùng LocalStack CLI thay vì Docker Compose. Khuyến nghị sử dụng Docker Compose (`docker-compose up -d`) cho deployment chính thức.

---

## 🧩 Các Module Terraform

### VPC Module

Tạo Virtual Private Cloud với:
- 1 VPC với CIDR 10.0.0.0/16
- 2 Public subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 Private subnets (10.0.3.0/24, 10.0.4.0/24)
- Internet Gateway
- Route tables

**File:** [terraform/aws/modules/vpc/main.tf](terraform/aws/modules/vpc/main.tf)

### EKS Module

Tạo Elastic Kubernetes Service cluster với:
- Kubernetes version 1.28
- Cluster name: project_1-{env}-eks
- Security groups cho cluster và nodes
- KMS encryption
- CloudWatch logging

**File:** [terraform/aws/modules/eks/main.tf](terraform/aws/modules/eks/main.tf)

> **Lưu ý**: EKS cluster sử dụng k3d backend của LocalStack, tạo Kubernetes cluster thật chạy trong Docker containers.

---

## 🐳 Docker Compose Services

### LocalStack

- **Image:** localstack/localstack-pro
- **Container name:** localstack-main
- **Ports:**
  - 4566 (Gateway API)
  - 4510-4559 (External services)
  - 443 (HTTPS)
- **Volumes:**
  - `./volume:/var/lib/localstack` (Data persistence)
  - `/var/run/docker.sock:/var/run/docker.sock` (Docker socket cho k3d)
- **Network:** localstack-net (bridge)
- **Environment:**
  - LOCALSTACK_AUTH_TOKEN (required)
  - DEBUG, PERSISTENCE (optional)

### Jenkins

- **Image:** jenkins-jdk-17 (custom build)
- **Container name:** jenkins
- **Ports:** 8080 (UI), 50000 (agent)
- **Volumes:** jenkins_home, Docker socket
- **Network:** localstack-net (bridge)
- **Environment:** LOCALSTACK_ENDPOINT=http://localstack:4566

### Ansible

- **Image:** ansible-controller (custom build)
- **Container name:** ansible
- **Volumes:** playbooks, inventory, roles
- **Network:** localstack-net (bridge)
- **Environment:**
  - LOCALSTACK_ENDPOINT=http://localstack:4566
  - AWS_ENDPOINT_URL=http://localstack:4566
- **Command:** tail -f /dev/null (keep alive)

**Giao tiếp giữa các services:**
- Tất cả services cùng network `localstack-net` → DNS resolution tự động
- Jenkins → LocalStack: `http://localstack:4566`
- Ansible → LocalStack: `http://localstack:4566`
- Host → LocalStack: `http://localhost:4566`

---

## 🔧 Cấu hình Terraform

### Providers

Terraform được cấu hình để sử dụng LocalStack endpoints:

```hcl
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true

  endpoints {
    ec2  = "http://localhost:4566"
    eks  = "http://localhost:4566"
    # ... other services
  }
}
```

### Variables

**Common variables** ([terraform/aws/env/common.tfvars](terraform/aws/env/common.tfvars)):
- vpc_cidr = "10.0.0.0/16"
- project = "project_1"
- region = "ap-southeast-1"
- public_subnet_cidrs, private_subnet_cidrs
- public_subnet_azs, private_subnet_azs

**Environment-specific** ([terraform/aws/env/dev.tfvars](terraform/aws/env/dev.tfvars)):
- env = "dev"

---

## 🐛 Xử lý Sự cố

### LocalStack license activation failed

**Lỗi:**
```
License activation failed! 🔑❌
Reason: The credentials defined in your environment are invalid.
```

**Giải pháp:**
1. Kiểm tra auth token:
   ```bash
   echo $LOCALSTACK_AUTH_TOKEN
   ```

2. Lấy token mới từ https://app.localstack.cloud

3. Set lại environment variable:
   ```bash
   export LOCALSTACK_AUTH_TOKEN=your-new-token
   ```

4. Khởi động lại LocalStack:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### EKS cluster creation failed - k3d not found

**Lỗi trong logs:**
```
Error starting K3D cluster: Installation of k3d v5.8.3 failed.
```

**Nguyên nhân:** LocalStack container không thể download k3d từ GitHub do rate limit hoặc network issues.

**Giải pháp 1 - Kiểm tra k3d binary:**
```bash
# Verify k3d được mount vào LocalStack container
docker exec localstack-main which k3d
docker exec localstack-main k3d version

# Nếu không có, restart Docker Compose
docker-compose restart localstack
```

**Giải pháp 2 - GitHub API Rate Limit:**

Xem phần [Known Issues & Workarounds](#%EF%B8%8F-known-issues--workarounds) để biết chi tiết về GitHub API rate limit và cách xử lý.

### Terraform state mismatch

**Lỗi:** Resources tồn tại trong state nhưng không có trên LocalStack.

**Giải pháp:**
```bash
# Clean state và deploy lại
cd terraform/aws
rm -rf .terraform.lock.hcl terraform.tfstate*
terraform init
./deploy.sh dev all --auto-approve
```

### LocalStack không khởi động

```bash
# Kiểm tra logs
docker logs localstack-main

# Kiểm tra containers
docker-compose ps

# Kiểm tra port
lsof -i :4566

# Restart
docker-compose restart localstack

# Hoặc rebuild
docker-compose down
docker-compose up -d --build
```

### Jenkins không kết nối LocalStack

```bash
# Kiểm tra endpoint từ Jenkins container (sử dụng service name)
docker exec jenkins curl http://localstack:4566/_localstack/health

# Kiểm tra network
docker network inspect localstack-net

# Verify cả hai containers cùng network
docker inspect jenkins | grep -A 10 Networks
docker inspect localstack-main | grep -A 10 Networks
```

---

## 📊 Outputs

Sau khi deploy thành công, bạn có thể xem outputs:

```bash
cd terraform/aws
terraform output

# Hoặc
terraform output vpc_id
terraform output eks_cluster_name
terraform output eks_cluster_endpoint
```

---

## 🎯 Điểm khác biệt với AWS Production

| Thành phần | AWS Production | LocalStack |
|-----------|----------------|------------|
| **Compute** | EC2 Instances | Docker Containers |
| **Kubernetes** | EKS (managed) | k3d (local k3s) |
| **Container Registry** | ECR | LocalStack ECR |
| **Networking** | VPC, Subnets, NAT | Mô phỏng qua LocalStack |
| **Storage** | S3 | LocalStack S3 |
| **Chi phí** | Có phát sinh | **Miễn phí** |
| **Performance** | Production-grade | Development-grade |

---

## 📚 Tài liệu Tham khảo

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [LocalStack EKS Support](https://docs.localstack.cloud/user-guide/aws/elastic-kubernetes-service/)
- [k3d Documentation](https://k3d.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible AWS Collections](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)

---

## 🎓 Mục đích Học tập

Dự án này giúp bạn:
- ✅ Hiểu rõ quy trình CI/CD end-to-end
- ✅ Thực hành Terraform Infrastructure as Code
- ✅ Làm việc với AWS services qua LocalStack
- ✅ Deploy EKS cluster với k3d
- ✅ Tích hợp Jenkins pipeline
- ✅ Sử dụng Ansible cho automation
- ✅ Quản lý multi-environment infrastructure (dev/prod)
- ✅ **Không mất chi phí AWS**

---

## 🔄 Workflow CI/CD

1. **Developer** push code lên GitHub
2. **GitHub Webhook** trigger Jenkins job
3. **Jenkins** chạy pipeline:
   - Checkout code
   - Build Docker image
   - Security scan (Trivy)
   - Push lên LocalStack ECR
   - Trigger Ansible playbook
4. **Ansible** deploy infrastructure/application:
   - Provision resources qua Terraform
   - Configure services
   - Deploy application lên EKS
5. **Kubernetes (k3d)** chạy application

---

## 🧹 Cleanup

```bash
# Destroy Terraform infrastructure
./deploy.sh dev destroy --auto-approve

# Stop LocalStack
source localstack/bin/activate
localstack stop

# Stop Docker services
docker-compose down

# Remove k3d clusters (nếu có)
k3d cluster list
k3d cluster delete <cluster-name>

# Deactivate venv
deactivate
```

---

## ⚠️ Known Issues & Workarounds

### 1. GitHub API Rate Limit với k3d Download (CRITICAL)

**Vấn đề**: LocalStack Pro EKS không thể tạo cluster do GitHub API rate limit khi validate k3d version.

**Triệu chứng**:
```
Error starting K3D cluster: Could not get list of releases from https://api.github.com/repos/rancher/k3d/releases/tags/v5.8.3:
{"message":"API rate limit exceeded for x.x.x.x. (But here's the good news: Authenticated requests get a higher rate limit..."}
```

Hoặc (trên WSL2):
```
Error starting K3D cluster: Installation of k3d v5.8.3 failed.
```

**Root cause**:
- LocalStack **luôn kiểm tra** GitHub API `/repos/rancher/k3d/releases/tags/v5.8.3` trước khi sử dụng k3d binary
- GitHub API rate limit cho unauthenticated requests: **60 requests/hour per IP**
- Trong môi trường WSL2/Docker, nhiều services có thể share cùng public IP → exhaust rate limit rất nhanh
- LocalStack **không có** environment variable để bypass GitHub check hoặc sử dụng authenticated requests ([Issue #7148](https://github.com/localstack/localstack/issues/7148))

**Workarounds đã test (KHÔNG hiệu quả)**:
- ❌ Mount k3d binary vào `/usr/local/bin/`: LocalStack vẫn check GitHub API
- ❌ Copy k3d vào `/var/lib/localstack/lib/k3d/v5.8.3/`: LocalStack vẫn check GitHub API trước
- ❌ MTU adjustments (1400, 1350): Không fix GitHub API issue
- ❌ Disable SSL verification: Không bypass rate limit

**Giải pháp khả thi**:

**Option 1: Chờ GitHub API rate limit reset (RECOMMENDED cho testing)**
```bash
# Check khi nào rate limit reset
curl -I https://api.github.com/repos/rancher/k3d/releases/tags/v5.8.3 2>&1 | grep -i "x-ratelimit"

# Đợi 1 giờ rồi thử lại
./deploy.sh dev all --auto-approve
```

**Option 2: Custom LocalStack Docker Image (RECOMMENDED cho production)**

Tạo image với k3d pre-installed và mock GitHub API response:
```dockerfile
# Dockerfile.localstack-eks
FROM localstack/localstack-pro:4.12.1

# Pre-install k3d binary vào internal directory
RUN mkdir -p /var/lib/localstack/lib/k3d/v5.8.3 && \
    wget -q -O /var/lib/localstack/lib/k3d/v5.8.3/k3d \
        https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-amd64 && \
    chmod +x /var/lib/localstack/lib/k3d/v5.8.3/k3d

# Note: LocalStack sẽ vẫn cố check GitHub API nhưng nếu fail sẽ fallback
# về binary đã có sẵn (behavior có thể thay đổi theo version)
```

Build và sử dụng:
```bash
docker build -t localstack-eks:latest -f Dockerfile.localstack-eks .

# Update start-localstack.sh để sử dụng custom image
# Thay vì: localstack start -d
# Sử dụng: docker run với custom image
```

**Option 3: Sử dụng GitHub Personal Access Token (experimental)**

LocalStack chưa official support nhưng có thể thử:
```bash
export GITHUB_TOKEN="ghp_your_token_here"
export DOCKER_FLAGS="... -e GITHUB_TOKEN=$GITHUB_TOKEN"
./start-localstack.sh
```

**Tham khảo**:
- [LocalStack Issue #7148 - GitHub API Rate Limit](https://github.com/localstack/localstack/issues/7148)
- [LocalStack Issue #6797 - Container CI Error](https://github.com/localstack/localstack/issues/6797)
- [LocalStack EKS Documentation](https://docs.localstack.cloud/aws/services/eks/)

### 2. LocalStack Data Persistence

**Vấn đề**: Khi restart LocalStack, tất cả resources (VPC, EKS clusters) bị mất.

**Giải pháp**:
- Destroy terraform state trước khi restart: `./deploy.sh dev destroy --auto-approve`
- Hoặc enable LocalStack persistence (Pro feature):
  ```bash
  export PERSISTENCE=1
  ./start-localstack.sh
  ```

### 3. Terraform State Mismatch

**Vấn đề**: Terraform state có resources cũ mà LocalStack không còn.

**Giải pháp**:
```bash
cd terraform/aws
rm terraform.tfstate*
./deploy.sh dev all --auto-approve
```

---

## 👥 Tác giả

**Tai Huu Nguyen** - DevOps Engineer

## 📬 Liên hệ

- 📧 Email: huutai.network@gmail.com
- GitHub: [0xt4i](https://github.com/0xt4i)

---

## 📝 License

MIT License - Dự án học tập, free to use

---

## 🙏 Credits

Dự án này được phát triển dựa trên kiến trúc từ:
- **Original Project**: [CloudDevOpsProject](https://github.com/Sherif127/CloudDevOpsProject)
- **Author**: Sherif Shaban
- **Adaptation**: Điều chỉnh để chạy trên LocalStack thay vì AWS thật, bổ sung k3d support cho EKS, phục vụ mục đích học tập

---

**Ghi chú**: Đây là môi trường mô phỏng cho mục đích học tập. Để triển khai production, cần thay LocalStack bằng AWS services thật và bổ sung security hardening, monitoring, backup strategies.
