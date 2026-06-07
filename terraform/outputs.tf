output "ecr_backend_url" {
  description = "ECR repository URL for the backend image."
  value       = module.ecr.backend_url
}

output "ecr_frontend_url" {
  description = "ECR repository URL for the frontend image."
  value       = module.ecr.frontend_url
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Hostname of the RDS PostgreSQL instance (sensitive)."
  value       = module.rds.endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}
