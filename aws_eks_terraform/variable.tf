variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "project_name" {
  type        = string
  description = "Project prefix/name"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (used for subnet tags)"
}

variable "name" {
  type        = string
  description = "Optional explicit VPC name override"
  default     = null
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  description = "AZs"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
############EKS_Var######
variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the EKS public endpoint (use YOUR_IP/32)"
  default     = []
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.micro"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_desired_size" {
  type    = number
  default = 2
}
# ...existing code...

variable "endpoint_public_access" {
  type    = bool
  default = true
  description = "Enable public access to EKS cluster endpoint"
}

variable "endpoint_private_access" {
  type    = bool
  default = true
  description = "Enable private access to EKS cluster endpoint"
}