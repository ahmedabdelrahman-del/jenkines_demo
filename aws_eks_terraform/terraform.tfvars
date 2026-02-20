aws_region   = "us-east-1"
project_name = "eks-lab"
cluster_name = "demo-eks-final"

name = "eks-vpc"

vpc_cidr = "10.0.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

enable_nat_gateway = true
single_nat_gateway = true

tags = {
  Project = "eks-lab"
  Owner   = "Ahmed"
}

public_access_cidrs = ["0.0.0.0/0"]

node_instance_types = ["t3.small"]
node_min_size       = 1
node_desired_size   = 1
node_max_size       = 1
cluster_version = "1.30"
endpoint_public_access  = true
endpoint_private_access = true