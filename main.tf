locals {
  # Each canary type maps to a source .py: browser canaries have a dedicated
  # src/<name>.py, while API and Domino canaries share a generic script that is
  # parameterized entirely via environment variables.
  source_names = {
    for k, c in var.cloudwatch_map : k => (
      c.type == "api" ? "api_canary" : c.type == "domino" ? "domino_canary" : c.name
    )
  }

  canaries = {
    for k, c in var.cloudwatch_map : k => {
      source_name = local.source_names[k]
      source_path = "${path.module}/src/${local.source_names[k]}.py"
      handler     = "${local.source_names[k]}.handler"
      # Only include the optional env vars that are actually set so the runtime
      # skips the checks/behaviour it wasn't configured for.
      environment_variables = (
        c.type == "api" ? merge(
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
          ) : c.type == "domino" ? merge(
          {
            DOMINO_HOST         = c.endpoint
            DOMINO_PROJECT_ID   = c.project_id
            DOMINO_ACTION       = coalesce(c.domino_action, "job")
            DOMINO_WORKSPACE_ID = c.workspace_id
          },
          # Prefer the Secrets Manager path; only fall back to plaintext if no secret ARN is set.
          c.api_key_secret_arn != null ? { DOMINO_API_KEY_SECRET_ID = c.api_key_secret_arn } : (c.api_key == null ? {} : { DOMINO_API_KEY = c.api_key }),
          c.api_key_secret_json_key == null ? {} : { DOMINO_API_KEY_SECRET_JSON_KEY = c.api_key_secret_json_key },
          c.run_command == null ? {} : { DOMINO_RUN_COMMAND = c.run_command },
          c.cleanup == null ? {} : { DOMINO_CLEANUP = tostring(c.cleanup) },
          c.max_latency_ms == null ? {} : { DOMINO_MAX_LATENCY_MS = tostring(c.max_latency_ms) },
        ) : {}
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
  start_canary          = each.value.start_canary
  schedule_expression   = coalesce(each.value.schedule_expression, "rate(5 minutes)")
  # Per-canary execution timeout (AWS caps 300s on <=5min schedules; domino
  # needs 600 for the workspace poll). Module default stays 600 for backward
  # compat with direct module users; this repo always sets it explicitly.
  timeout_in_seconds = coalesce(each.value.timeout_in_seconds, 300)

  execution_role_arn = aws_iam_role.canary.arn
  artifact_s3_bucket = aws_s3_bucket.canary_output.bucket

  vpc_config = local.canary_vpc_config
}
