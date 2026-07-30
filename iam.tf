locals {
  # Secrets Manager ARNs referenced by Domino canaries — the canary role gets
  # scoped GetSecretValue access to exactly these, and nothing when there are none.
  domino_secret_arns = distinct([
    for c in var.cloudwatch_map : c.api_key_secret_arn
    if c.type == "domino" && c.api_key_secret_arn != null
  ])
}

# Shared execution role assumed by every canary.
resource "aws_iam_role" "canary" {
  name        = "my-cloudwatch-syn-role"
  description = "Role used to provide permissions for the canary to run."
  managed_policy_arns = concat(
    [aws_iam_policy.canary_put_object.arn, aws_iam_policy.canary_permissions.arn],
    length(local.domino_secret_arns) > 0 ? [aws_iam_policy.canary_secrets[0].arn] : [],
  )
  assume_role_policy = file("${path.module}/policies/assume_role.json")
}

resource "aws_iam_policy" "canary_secrets" {
  count = length(local.domino_secret_arns) > 0 ? 1 : 0
  name  = "policy-6180333"

  policy = templatefile("${path.module}/policies/canary_secrets.json.tftpl", {
    secret_arns = jsonencode(local.domino_secret_arns)
  })
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
