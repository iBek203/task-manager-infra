data "aws_iam_user" "ci" {
  user_name = "terraform-ci"
}

resource "aws_iam_user_policy" "ci" {
  name   = "terraform-ci-policy"
  user   = data.aws_iam_user.ci.user_name
  policy = file("${path.module}/ci-policy.json")
}
