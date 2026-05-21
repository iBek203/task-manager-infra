resource "aws_iam_user" "ecr_ci" {
  name = "${var.project}-ecr-ci"
}

resource "aws_iam_user_policy" "ecr_ci" {
  name = "${var.project}-ecr-ci-policy"
  user = aws_iam_user.ecr_ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetAuthToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "PushImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          aws_ecr_repository.backend.arn,
          aws_ecr_repository.frontend.arn
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "ecr_ci" {
  user = aws_iam_user.ecr_ci.name
}

output "ecr_ci_access_key_id" {
  value     = aws_iam_access_key.ecr_ci.id
  sensitive = true
}

output "ecr_ci_secret_access_key" {
  value     = aws_iam_access_key.ecr_ci.secret
  sensitive = true
}
