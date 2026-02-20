variable "name" {
  description = "Base name/prefix for VPC resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least 2 AZs for high availability."
  }
}

variable "public_subnets" {
  description = "Public subnet CIDRs (must match azs length)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) > 0
    error_message = "Provide at least one public subnet CIDR."
  }
}

variable "private_subnets" {
  description = "Private subnet CIDRs (must match azs length)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "Provide at least one private subnet CIDR."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Single NAT (cheap) vs NAT per AZ (HA)"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet discovery tags (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
