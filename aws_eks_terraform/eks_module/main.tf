module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  endpoint_public_access       = var.endpoint_public_access
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access_cidrs = var.public_access_cidrs

  enable_irsa = true

  create_cloudwatch_log_group = false
  node_security_group_enable_recommended_rules = true

  eks_managed_node_groups = {
    (var.node_group_name) = {
      name           = var.node_group_name
      subnet_ids     = var.private_subnet_ids
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }

  tags = var.tags
}
