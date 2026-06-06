variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where the GitHub Actions OIDC provider and IAM role are created."
}

variable "project" {
  type        = string
  default     = "task-manager"
  description = "Project name used as a prefix for IAM resource names."
}
