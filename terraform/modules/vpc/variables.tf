variable "project" {
  type        = string
  description = "Project name prefix for resource naming and tagging."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per AZ, used by ALB and NAT gateway)."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per AZ, used by EKS nodes and RDS)."
}
