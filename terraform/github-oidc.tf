data "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions"
}

removed {
  from = aws_iam_openid_connect_provider.github
  lifecycle { destroy = false }
}

removed {
  from = aws_iam_role.github_actions
  lifecycle { destroy = false }
}

removed {
  from = aws_iam_role_policy.github_actions
  lifecycle { destroy = false }
}

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_role.github_actions.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}

output "github_actions_role_arn" {
  value = data.aws_iam_role.github_actions.arn
}
