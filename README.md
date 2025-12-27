# 🌐 Hệ thống CI/CD Pipeline GitOps End-to-End với LocalStack

Một hệ thống hạ tầng CI/CD hoàn chỉnh cho ứng dụng container sử dụng **LocalStack** để mô phỏng môi trường AWS. Dự án này sử dụng **Terraform** để khởi tạo hạ tầng AWS (qua LocalStack), **Jenkins** cho continuous integration, **Ansible** cho automation và configuration management, và **ArgoCD** cho GitOps-based deployment lên **Kubernetes** cluster.

> **Lưu ý**: Đây là môi trường **học tập và phát triển** sử dụng LocalStack để mô phỏng các dịch vụ AWS mà không phát sinh chi phí.

---

## 📐 Kiến trúc Dự án

![Architecture](https://github.com/user-attachments/assets/4881fd5d-7aa4-48e7-b55a-3f19b24b112d)

---

## 🏗️ Tổng quan Kiến trúc

### 1. ☁️ Hạ tầng AWS (Được mô phỏng bởi LocalStack)

- **LocalStack Container**:
  - Mô phỏng các dịch vụ AWS: S3, ECR, EKS, SNS, SES, IAM, Lambda, API Gateway
  - Chạy trên cổng 4566 (Gateway)
  - Hỗ trợ Terraform để provision resources

- **Jenkins Container**:
  - Jenkins Master để điều phối CI pipeline
  - Thực thi các jobs: build, test, scan, deploy

- **Ansible Container**:
  - Automation và configuration management
  - Deploy resources lên LocalStack/AWS
  - Quản lý infrastructure state

- **Các dịch vụ AWS được mô phỏng**:
  - **S3**: Lưu trữ Terraform state, artifacts
  - **ECR**: Container registry để lưu Docker images
  - **SNS/SES**: Gửi thông báo email
  - **EKS**: Kubernetes cluster (hoặc dùng Minikube/Kind local)
  - **IAM**: Quản lý permissions và roles

---

### 2. ⚙️ Quản lý Cấu hình

- **Docker Compose**:
  - Quản lý lifecycle của LocalStack, Jenkins và Ansible containers
  - Kết nối các services qua Docker network chung (cicd_network)

- **Terraform**:
  - Infrastructure as Code để khởi tạo resources trên LocalStack
  - Quản lý state file
  - Tự động provision S3 buckets, ECR repos, Lambda functions, etc.

- **Ansible**:
  - Configuration management và automation tasks
  - Deploy và configure AWS resources trên LocalStack
  - Tích hợp với Jenkins pipeline để orchestrate deployments

- **Init Scripts**:
  - Tự động khởi tạo resources khi LocalStack startup
  - Setup initial configurations

---

### 3. 💻 Môi trường Kubernetes

- **Local Kubernetes Cluster** (Minikube/Kind/K3s):
  - Thay thế cho EKS thật
  - Hosting ứng dụng trong namespace riêng
  - Xử lý deployments qua Kubernetes manifests

---

### 4. 🔁 ArgoCD (GitOps Deployment)

- **Các thành phần chính**:
  - **Application Controller**: Đảm bảo trạng thái app khớp với Git
  - **Repository Server**: Cache Git manifests
  - **GitOps Engine**: Thực thi sync operations

- **Quy trình triển khai**:
  1. Theo dõi GitHub repo để phát hiện thay đổi manifests
  2. Tự động sync thay đổi lên Kubernetes cluster
  3. Duy trì trạng thái khai báo từ version control

---

### 5. ⚙️ Luồng CI/CD Pipeline

1. **Code push** kích hoạt webhook trong GitHub
2. **Jenkins**:
   - Phát hiện thay đổi và lên lịch job
   - Chạy unit tests
   - Build Docker image
   - Scan vulnerabilities với **Trivy**
   - Push image lên **LocalStack ECR**
   - Cập nhật Kubernetes manifests với image tag mới
   - Commit manifest changes về GitHub
3. **ArgoCD**:
   - Phát hiện commit mới trong GitHub repo
   - Sync manifests đã cập nhật lên Kubernetes cluster
4. **Ứng dụng** được deploy/update tự động trên Kubernetes

---

## ✅ Yêu cầu Tiên quyết

- Docker & Docker Compose đã cài đặt
- Git đã cài đặt
- LocalStack Auth Token (cho LocalStack Pro features)
- Minikube hoặc Kind (cho local Kubernetes)
- Terraform CLI
- Có thể cần: kubectl, helm

---

## 📁 Cấu trúc Dự án

```bash
.
├── docker-compose.yaml      # Docker Compose gộp chung: LocalStack, Jenkins, Ansible
├── localstack/              # LocalStack configuration và init scripts
│   ├── init-resources.sh    # Script khởi tạo resources
│   ├── lambda-functions/    # Lambda function code
│   └── volume/              # LocalStack persistent data
├── jenkins/                 # Jenkins docker setup
│   ├── Dockerfile           # Custom Jenkins image với tools
│   └── ...                  # Jenkins configurations
├── ansible/                 # Ansible automation
│   ├── Dockerfile           # Ansible controller image
│   ├── ansible.cfg          # Ansible configuration
│   ├── playbooks/           # Ansible playbooks
│   ├── inventory/           # Inventory files (hosts)
│   └── roles/               # Ansible roles
├── terraform/               # Terraform modules & scripts
│   ├── aws/                 # AWS resources configuration
│   ├── deploy.sh            # Deploy script
│   └── destroy.sh           # Cleanup script
└── README.md                # File documentation chính
```

---

## 🧱 Các Thành phần Dự án

### 🚀 LocalStack (Mô phỏng AWS Services)

Mô phỏng các dịch vụ AWS:
- S3 buckets cho artifacts và Terraform state
- ECR repositories cho Docker images
- Lambda functions
- SNS topics cho notifications
- IAM roles và policies

**Cách khởi động**:
```bash
# Chạy tất cả services từ root
export LOCALSTACK_AUTH_TOKEN=your-token-here
docker-compose up -d
```

---

### 🤖 Ansible (Automation & Configuration Management)

**Mục đích**:
- Tự động hóa deployment resources lên LocalStack/AWS
- Configuration management cho infrastructure
- Orchestration tasks trong CI/CD pipeline

**Cấu trúc**:
- **Inventory**: Định nghĩa các target hosts (localhost, LocalStack)
- **Playbooks**: Kịch bản automation (YAML format)
- **Roles**: Tái sử dụng logic cho các tasks phổ biến

**Ví dụ sử dụng**:
```bash
# Chạy playbook từ Ansible container
docker exec ansible-controller ansible-playbook \
  -i /ansible/inventory/hosts \
  /ansible/playbooks/deploy-to-localstack.yml

# Hoặc từ Jenkins pipeline
docker exec ansible-controller ansible-playbook /ansible/playbooks/setup.yml
```

**Tính năng chính**:
- ✅ Deploy AWS resources (S3, Lambda, DynamoDB) lên LocalStack
- ✅ Configure applications và services
- ✅ Idempotent operations (chạy nhiều lần không gây lỗi)
- ✅ Tích hợp với Jenkins pipeline

---

### 🏗️ Terraform (Infrastructure as Code)

Tự động khởi tạo:
- S3 buckets trên LocalStack
- ECR repositories
- Lambda functions
- SNS topics cho email alerts
- IAM roles và policies

**Cách sử dụng**:
```bash
cd terraform
# Cấu hình endpoint trỏ về LocalStack
terraform init
terraform plan
terraform apply
```

---

### 🛠️ Jenkins (CI/CD Pipeline)

Bao gồm:
- Pipeline stages:
  - Checkout Code
  - Build & Push Docker Image
  - Security Scan (Trivy)
  - Push to LocalStack ECR
  - Update Kubernetes manifests

**Cách khởi động**:
```bash
cd jenkins
docker-compose up -d
# Truy cập: http://localhost:8080
```

---

### 🐳 Docker (Application Containerization)

- Ứng dụng mẫu (Flask/Node.js/Java)
- Dockerfile tối ưu với multi-stage build
- Push images lên LocalStack ECR thay vì Docker Hub

---

### ☸️ Kubernetes (Container Orchestration)

- Deployment và Service manifests
- Namespace configuration
- Manifests tự động cập nhật qua Jenkins pipeline

**Setup local K8s**:
```bash
# Sử dụng Minikube
minikube start

# Hoặc Kind
kind create cluster --name cicd-demo
```

---

### 🚀 ArgoCD (GitOps Continuous Deployment)

- Tự động sync manifests từ GitHub
- Deploy ứng dụng lên local Kubernetes cluster

**Cài đặt ArgoCD**:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 🚀 Hướng dẫn Triển khai

### Bước 1: Khởi động tất cả services (LocalStack, Jenkins, Ansible)
```bash
# Từ thư mục root của project
export LOCALSTACK_AUTH_TOKEN=your-token
docker-compose up -d

# Kiểm tra trạng thái
docker-compose ps
```

### Bước 2: Verify các containers đang chạy
```bash
# Kiểm tra logs
docker-compose logs -f localstack
docker-compose logs -f jenkins
docker-compose logs -f ansible
```

### Bước 3: Provision Infrastructure với Terraform
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### Bước 4: Setup Local Kubernetes
```bash
minikube start
kubectl create namespace demo-app
```

### Bước 5: Cài đặt ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Bước 6: Test Ansible
```bash
# Test kết nối Ansible
docker exec ansible-controller ansible --version

# Chạy playbook mẫu (nếu có)
docker exec ansible-controller ansible-playbook /ansible/playbooks/test.yml
```

### Bước 7: Cấu hình Jenkins Pipeline
- Truy cập Jenkins UI: http://localhost:8080
- Tạo Pipeline job
- Cấu hình Git webhook
- Pipeline có thể gọi Ansible để orchestrate deployments

---

## 🎯 Điểm khác biệt với AWS Production

| Thành phần | AWS Production | LocalStack (Học tập) |
|-----------|----------------|---------------------|
| **Compute** | EC2 Instances | Docker Containers |
| **Container Registry** | ECR | LocalStack ECR |
| **Kubernetes** | EKS | Minikube/Kind |
| **Storage** | S3 | LocalStack S3 |
| **Notifications** | SNS/SES | LocalStack SNS/SES |
| **Chi phí** | Có phát sinh | **Miễn phí** |
| **Networking** | VPC, Subnets | Docker Networks |

---

## 📚 Tài liệu Tham khảo

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform LocalStack Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/custom-service-endpoints)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible AWS Collections](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Minikube Guide](https://minikube.sigs.k8s.io/docs/)

---

## 🎓 Mục đích Học tập

Dự án này giúp bạn:
- ✅ Hiểu rõ quy trình CI/CD end-to-end
- ✅ Thực hành với Terraform IaC
- ✅ Làm việc với Jenkins pipeline
- ✅ Học Ansible cho automation và configuration management
- ✅ Áp dụng GitOps với ArgoCD
- ✅ Triển khai ứng dụng lên Kubernetes
- ✅ Tích hợp security scanning (Trivy)
- ✅ **Không mất chi phí AWS**

---

## 🐛 Xử lý Sự cố

### LocalStack không khởi động
```bash
# Kiểm tra logs
docker logs localstack

# Kiểm tra auth token
echo $LOCALSTACK_AUTH_TOKEN
```

### Terraform không kết nối được LocalStack
```bash
# Đảm bảo endpoint configuration
export AWS_ENDPOINT_URL=http://localhost:4566
```

### Jenkins không push được lên ECR
```bash
# Login vào LocalStack ECR
aws --endpoint-url=http://localhost:4566 ecr get-login-password | docker login --username AWS --password-stdin localhost:4566
```

---

## Tác giả

**Tai Huu Nguyen** - DevOps Engineer

## 📬 Liên hệ

- 📧 Email huutai.network@gmail.com
- GitHub: [0xt4i](https://github.com/0xt4i)

---

## 📝 License

MIT License - Dự án học tập, free to use

---

## 🙏 Credits

Dự án này được phát triển dựa trên kiến trúc từ:
- **Original Project**: [CloudDevOpsProject](https://github.com/Sherif127/CloudDevOpsProject)
- **Author**: Sherif Shaban
- **Adaptation**: Điều chỉnh để chạy trên LocalStack thay vì AWS thật, phục vụ mục đích học tập

---

**Ghi chú**: Đây là môi trường mô phỏng cho mục đích học tập. Để triển khai production, cần thay LocalStack bằng AWS services thật và bổ sung security hardening, monitoring, backup strategies.
