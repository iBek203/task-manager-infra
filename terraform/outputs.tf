output "ecr_backend_url" {
  description = "ECR repository URL for the backend image."
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  description = "ECR repository URL for the frontend image."
  value       = aws_ecr_repository.frontend.repository_url
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "rds_endpoint" {
  description = "Hostname of the RDS PostgreSQL instance (sensitive)."
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}
