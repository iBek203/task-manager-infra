output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider, used by IRSA role trust policies."
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_issuer" {
  description = "OIDC issuer hostname (without https://) used as a condition key in IRSA trust policies."
  value       = local.oidc_issuer
}
