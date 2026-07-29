locals {
  # Resolve per-canary source file, handler, and runtime env vars by type.
  # Browser canaries have a dedicated src/<name>.py; API canaries share the
  # generic src/api_canary.py and receive their target via environment variables.
  canaries = {
    for k, c in var.cloudwatch_map : k => {
      source_name = c.type == "api" ? "api_canary" : c.name
      source_path = "${path.module}/src/${c.type == "api" ? "api_canary" : c.name}.py"
      handler     = c.type == "api" ? "api_canary.handler" : "${c.name}.handler"
      # API canaries are parameterized entirely via env vars; only include the
      # optional assertion vars that are actually set so the runtime skips the rest.
      environment_variables = c.type != "api" ? {} : merge(
        {
          API_ENDPOINT = c.endpoint
          API_METHOD   = c.method
        },
        c.expected_status == null ? {} : { API_EXPECTED_STATUS = tostring(c.expected_status) },
        c.max_latency_ms == null ? {} : { API_MAX_LATENCY_MS = tostring(c.max_latency_ms) },
        c.body_contains == null ? {} : { API_BODY_CONTAINS = c.body_contains },
        c.json_assertions == null ? {} : { API_JSON_ASSERTIONS = jsonencode(c.json_assertions) },
        c.request_headers == null ? {} : { API_REQUEST_HEADERS = jsonencode(c.request_headers) },
        c.request_body == null ? {} : { API_REQUEST_BODY = c.request_body },
      )
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
