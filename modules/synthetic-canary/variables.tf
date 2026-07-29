variable "name" {
  type        = string
  description = "Name of the canary. Also used as the alarm name, SNS topic name, and Lambda handler prefix (<name>.handler)."
}

variable "sns_topic_email" {
  type        = string
  description = "Email address subscribed to the canary's alarm SNS topic."
}

variable "zip_file" {
  type        = string
  description = "Path to the zipped canary source bundle."
}

variable "handler" {
  type        = string
  description = "Entry point for the canary, in the form <file>.<function> (e.g. \"google.handler\" or \"api_canary.handler\")."
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables passed to the canary at runtime (e.g. the API endpoint for an API canary)."
  default     = {}
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the IAM role the canary assumes when it runs."
}

variable "artifact_s3_bucket" {
  type        = string
  description = "Name of the S3 bucket where canary run artifacts are stored."
}

variable "runtime_version" {
  type        = string
  description = "Synthetics runtime version."
  default     = "syn-python-selenium-11.1"
}

variable "schedule_expression" {
  type        = string
  description = "Rate or cron expression controlling how often the canary runs."
  default     = "rate(5 minutes)"
}

variable "start_canary" {
  type        = bool
  description = "Whether to start the canary immediately after creation."
  default     = true
}

variable "delete_lambda" {
  type        = bool
  description = "Whether to delete the underlying Lambda when the canary is destroyed."
  default     = true
}

variable "alarm_comparison_operator" {
  type        = string
  description = "Comparison operator for the success-percent alarm."
  default     = "LessThanThreshold"
}

variable "alarm_threshold" {
  type        = number
  description = "SuccessPercent threshold below which the alarm fires."
  default     = 100
}

variable "alarm_evaluation_periods" {
  type        = number
  description = "Number of periods over which data is evaluated for the alarm."
  default     = 2
}

variable "alarm_period" {
  type        = number
  description = "Length in seconds of each alarm evaluation period."
  default     = 300
}
