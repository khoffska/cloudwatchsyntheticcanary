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
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      environment_variables = var.environment_variables
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
