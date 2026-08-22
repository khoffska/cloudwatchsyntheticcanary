# Build the DOMINO_* runtime env vars from the optional domino object so
# callers can pass `domino = {}` instead of hand-assembling env vars.
locals {
  domino_env = var.domino == null ? {} : merge(
    {
      DOMINO_HOST       = var.domino.endpoint
      DOMINO_PROJECT_ID = var.domino.project_id
      DOMINO_ACTION     = var.domino.action
    },
    var.domino.workspace_id != null ? { DOMINO_WORKSPACE_ID = var.domino.workspace_id } : {},
    var.domino.api_key_ssm_name != null ? { DOMINO_API_KEY_SSM_NAME = var.domino.api_key_ssm_name } : (
      var.domino.api_key != null ? { DOMINO_API_KEY = var.domino.api_key } : {}
    ),
    var.domino.run_command != null ? { DOMINO_RUN_COMMAND = var.domino.run_command } : {},
    var.domino.cleanup != null ? { DOMINO_CLEANUP = tostring(var.domino.cleanup) } : {},
    var.domino.max_latency_ms != null ? { DOMINO_MAX_LATENCY_MS = tostring(var.domino.max_latency_ms) } : {},
  )
}

resource "aws_synthetics_canary" "this" {
  name                 = var.name
  artifact_s3_location = "s3://${var.artifact_s3_bucket}/"
  execution_role_arn   = var.execution_role_arn
  zip_file             = var.zip_file
  handler              = var.handler
  runtime_version      = var.runtime_version
  delete_lambda        = var.delete_lambda

  schedule {
    expression = var.schedule_expression
  }

  dynamic "run_config" {
    for_each = length(merge(var.environment_variables, local.domino_env)) > 0 ? [1] : []
    content {
      environment_variables = merge(var.environment_variables, local.domino_env)
    }
  }

  start_canary = var.start_canary

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name                = var.name
  comparison_operator       = var.alarm_comparison_operator
  evaluation_periods        = var.alarm_evaluation_periods
  metric_name               = "SuccessPercent"
  namespace                 = "CloudWatchSynthetics"
  threshold                 = var.alarm_threshold
  statistic                 = "Average"
  period                    = var.alarm_period
  alarm_description         = "This alarm fires if the canary fails"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.this.arn]

  dimensions = {
    CanaryName = var.name
  }
}

resource "aws_sns_topic" "this" {
  name = var.name
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.sns_topic_email

  depends_on = [aws_sns_topic.this]
}
