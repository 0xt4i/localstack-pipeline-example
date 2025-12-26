module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.vpc_cidr
  name                  = "${var.project}-${var.env}-vpc"
  env                   = var.env
  project               = var.project
  public_subnet_cidrs   = var.public_subnet_cidrs
  public_subnet_azs     = var.public_subnet_azs
  private_subnet_cidrs  = var.private_subnet_cidrs
  private_subnet_azs    = var.private_subnet_azs
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "${var.project}-${var.env}-eks"
  cluster_version = "1.28"
  subnet_ids      = module.vpc.public_subnet_ids
  vpc_id          = module.vpc.vpc_id
  env             = var.env
  project         = var.project
  region          = var.region
  depends_on      = [module.vpc]
  # Truyền thêm các biến khác nếu module eks yêu cầu
}

