variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version, e.g. 1.29"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN (for IRSA)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags"
}
