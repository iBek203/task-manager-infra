locals {
  db_url = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/taskmanager"
}

resource "kubernetes_namespace" "prod" {
  metadata { name = "prod" }

  depends_on = [aws_eks_node_group.prod]
}

resource "kubernetes_namespace" "dev" {
  metadata { name = "dev" }

  depends_on = [aws_eks_fargate_profile.dev]
}

resource "kubernetes_secret" "db_secret_prod" {
  metadata {
    name      = "db-secret"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }
  data = {
    DATABASE_URL = local.db_url
  }
}

resource "kubernetes_secret" "db_secret_dev" {
  metadata {
    name      = "db-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  data = {
    DATABASE_URL = local.db_url
  }
}

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
