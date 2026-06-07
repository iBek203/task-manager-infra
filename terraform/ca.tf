resource "aws_iam_role" "ca" {
  name = "${var.project}-ca"

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
          "${module.eks.oidc_issuer}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          "${module.eks.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "ca" {
  name   = "${var.project}-ca"
  policy = file("${path.module}/ca-policy.json")
}

resource "aws_iam_role_policy_attachment" "ca" {
  role       = aws_iam_role.ca.name
  policy_arn = aws_iam_policy.ca.arn
}

output "ca_role_arn" {
  description = "ARN of the IRSA role used by the Cluster Autoscaler service account."
  value       = aws_iam_role.ca.arn
}
