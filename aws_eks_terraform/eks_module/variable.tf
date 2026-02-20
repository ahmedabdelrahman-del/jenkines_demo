variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version (e.g., 1.29, 1.30)"
  default     = "1.29"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the cluster and node groups"
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs for public EKS endpoint access"
  default     = []
}

variable "node_group_name" {
  type    = string
  default = "private-ng"
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

variable "tags" {
  type    = map(string)
  default = {}
}
