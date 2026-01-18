# Nodegroup cho EKS cluster (dùng cho LocalStack/k3d, không cần EC2 instance)
resource "aws_eks_node_group" "worker" {
  cluster_name    = var.cluster_name
  node_group_name = "nodegroup1"
  node_role_arn   = "arn:aws:iam::000000000000:role/eks-nodegroup-role"
  subnet_ids      = var.subnet_ids
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  depends_on = [aws_iam_role.worker_role]
  tags = {
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}
# IAM role for EC2 worker nodes
resource "aws_iam_role" "worker_role" {
  name_prefix = "eks-worker-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}

# Attach EKS worker node policy
resource "aws_iam_role_policy_attachment" "worker_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "worker_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "worker_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_role.name
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "worker_profile" {
  name_prefix = "eks-worker-"
  role        = aws_iam_role.worker_role.name
}

# Security group for worker nodes
resource "aws_security_group" "worker_sg" {
  name_prefix = "eks-worker-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow traffic between nodes
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # Allow traffic from cluster
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

## --- Disabled EC2 instance resources for LocalStack ---
# resource "aws_instance" "worker_nodes" { ... }
# resource "aws_instance" "ansible_controller" { ... }
