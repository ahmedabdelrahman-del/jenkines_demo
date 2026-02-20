module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.oidc_provider_arn

  enable_metrics_server               = true
  enable_aws_load_balancer_controller = true

  eks_addons = {
    # ✅ essentials (حل مشكلة NotReady)
    vpc-cni = {
      addon_version = "v1.21.1-eksbuild.3" # اللي طلعته لـ k8s 1.30
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }

    # ✅ storage
    aws-ebs-csi-driver = {
      most_recent = true
      configuration_values = <<-EOF
        {
          "default": {
            "enableVolumeScheduling": true,
            "enableVolumeResizing": true,
            "enableVolumeSnapshot": true
          }
        }
      EOF
    }
  }

  tags = var.tags
}
