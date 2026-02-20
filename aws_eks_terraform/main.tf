module "vpc" {
  source = "./vpc_eks"

  name            = var.name != null ? var.name : "${var.project_name}-vpc"
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  cluster_name = var.cluster_name
  tags         = var.tags
}

module "eks" {
  source = "./eks_module"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access
  public_access_cidrs     = var.public_access_cidrs

  node_group_name     = "private-ng"
  node_instance_types = ["t3.micro"]
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size

  tags = var.tags
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.eks.cluster_name,
      "--region", var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", module.eks.cluster_name,
        "--region", var.aws_region
      ]
    }
  }
}


module "addons" {
  source = "./addon_eks"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  tags              = var.tags

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

