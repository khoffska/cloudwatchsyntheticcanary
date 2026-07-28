output "canary_id" {
  description = "ID of the synthetics canary."
  value       = aws_synthetics_canary.this.id
}

output "canary_arn" {
  description = "ARN of the synthetics canary."
  value       = aws_synthetics_canary.this.arn
}

output "sns_topic_arn" {
  description = "ARN of the alarm SNS topic."
  value       = aws_sns_topic.this.arn
}

output "alarm_arn" {
  description = "ARN of the CloudWatch metric alarm."
  value       = aws_cloudwatch_metric_alarm.this.arn
}
