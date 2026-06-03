resource "aws_iam_user_policy" "ci_velero_s3" {
  name = "velero-s3"
  user = "terraform-ci"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "VeleroS3"
      Effect = "Allow"
      Action = [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetEncryptionConfiguration",
        "s3:PutEncryptionConfiguration",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketAcl",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucketMultipartUploads"
      ]
      Resource = [
        "arn:aws:s3:::${var.project}-velero-backups",
        "arn:aws:s3:::${var.project}-velero-backups/*"
      ]
    }]
  })
}
