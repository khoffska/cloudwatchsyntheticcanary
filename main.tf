locals {
  # Resolve per-canary source file, handler, and runtime env vars by type.
  # Browser canaries have a dedicated src/<name>.py; API canaries share the
  # generic src/api_canary.py and receive their target via environment variables.
  canaries = {
    for k, c in var.cloudwatch_map : k => {
      source_name = c.type == "api" ? "api_canary" : c.name
      handler     = c.type == "api" ? "api_canary.handler" : "${c.name}.handler"
      environment_variables = c.type == "api" ? {
        API_ENDPOINT = c.endpoint
        API_METHOD   = c.method
      } : {}
    }
  }
}

module "canary" {
  source   = "./modules/synthetic-canary"
  for_each = var.cloudwatch_map

  name                  = each.value.name
  sns_topic_email       = each.value.sns_topic_email
  zip_file              = data.archive_file.canary[each.key].output_path
  handler               = local.canaries[each.key].handler
  environment_variables = local.canaries[each.key].environment_variables

  execution_role_arn = aws_iam_role.canary.arn
  artifact_s3_bucket = aws_s3_bucket.canary_output.bucket
}
