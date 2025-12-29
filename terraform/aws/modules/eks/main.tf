module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # For LocalStack with Kind backend, worker nodes are managed by Kind
  # No need to create managed node groups explicitly

  tags = {
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}