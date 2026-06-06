variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where all resources are deployed."
}

variable "project" {
  type        = string
  default     = "task-manager"
  description = "Project name used as a prefix for resource names and tags."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDR blocks for the public subnets (one per AZ)."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  description = "CIDR blocks for the private subnets (one per AZ)."
}

variable "node_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for the EKS managed node group (prod)."
}

variable "node_max_size" {
  type        = number
  default     = 3
  description = "Maximum number of nodes in the EKS managed node group."
}

variable "db_username" {
  type        = string
  default     = "taskuser"
  description = "Master username for the RDS PostgreSQL instance."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Master password for the RDS PostgreSQL instance. Supplied via TF_VAR_db_password in CI."
}

variable "domain_name" {
  type        = string
  default     = "oybek.xyz"
  description = "Root domain name used for Route 53 DNS and ACM certificate provisioning."
}
