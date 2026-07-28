# Shared execution role assumed by every canary.
resource "aws_iam_role" "canary" {
  name                = "my-cloudwatch-syn-role"
  description         = "Role used to provide permissions for the canary to run."
  managed_policy_arns = [aws_iam_policy.canary_put_object.arn, aws_iam_policy.canary_permissions.arn]
  assume_role_policy  = file("${path.module}/policies/assume_role.json")
}

resource "aws_iam_policy" "canary_put_object" {
  name = "policy-618033"

  policy = templatefile("${path.module}/policies/canary_put_object.json.tftpl", {
    bucket_arn = aws_s3_bucket.canary_output.arn
  })
}

resource "aws_iam_policy" "canary_permissions" {
  name = "policy-6180332"

  policy = templatefile("${path.module}/policies/canary_permissions.json.tftpl", {
    bucket_arn = aws_s3_bucket.canary_output.arn
  })
}
