resource "aws_eks_access_entry" "ecr_ci" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_user.ecr_ci.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ecr_ci" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_user.ecr_ci.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ecr_ci]
}
