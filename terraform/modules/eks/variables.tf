variable "project" {
  type        = string
  description = "Project name prefix for resource naming and tagging."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of private subnets for EKS worker nodes, Fargate pods, and the cluster API endpoint."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of public subnets included in the cluster VPC config for ALB target discovery."
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for the managed node group."
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes in the managed node group."
}
