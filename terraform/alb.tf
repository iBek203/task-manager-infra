resource "aws_iam_role" "lbc" {
  name = "${var.project}-lbc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_issuer}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${module.eks.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "lbc" {
  name   = "${var.project}-lbc"
  policy = file("${path.module}/lbc-policy.json")
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

output "lbc_role_arn" {
  description = "ARN of the IRSA role used by the AWS Load Balancer Controller service account."
  value       = aws_iam_role.lbc.arn
}

output "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider used for IRSA role trust policies."
  value       = module.eks.oidc_provider_arn
}
