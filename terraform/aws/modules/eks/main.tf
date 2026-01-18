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

  # Disable managed node groups for LocalStack (not fully supported)
  # Nodes would need to be created separately or via ECS/Fargate
  eks_managed_node_groups = {}

  tags = {
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}