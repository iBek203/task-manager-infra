variable "project" {
  type        = string
  description = "Project name prefix for resource naming and tagging."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the RDS instance is deployed."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block allowed to connect to PostgreSQL on port 5432."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of private subnets used for the RDS subnet group."
}

variable "db_username" {
  type        = string
  description = "Master username for the PostgreSQL instance."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Master password for the PostgreSQL instance."
}
