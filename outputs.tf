output "artifact_bucket" {
  description = "Name of the shared canary artifact bucket."
  value       = aws_s3_bucket.canary_output.bucket
}

output "execution_role_arn" {
  description = "ARN of the shared canary execution role."
  value       = aws_iam_role.canary.arn
}

output "canaries" {
  description = "Per-canary IDs, alarm ARNs, and SNS topic ARNs, keyed by cloudwatch_map key."
  value = {
    for k, m in module.canary : k => {
      canary_id     = m.canary_id
      canary_arn    = m.canary_arn
      alarm_arn     = m.alarm_arn
      sns_topic_arn = m.sns_topic_arn
    }
  }
}
