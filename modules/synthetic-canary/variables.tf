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

variable "domino" {
  type = object({
    endpoint         = string                  # required: Domino host base URL, e.g. https://domino.example.com
    project_id       = string                  # required: target Domino project id
    workspace_id     = optional(string)        # required when action = "workspace" — target workspace id
    action           = optional(string, "job") # "job" | "workspace"
    run_command      = optional(string)        # job run command (default "main.py")
    cleanup          = optional(bool, true)    # stop what we started so no paid compute is left running
    max_latency_ms   = optional(number)        # fail if start request exceeds this
    api_key_ssm_name = optional(string)        # SSM Parameter Store param name (SecureString, preferred)
    api_key          = optional(string)        # plaintext fallback — avoid for real secrets
  })
  description = "Domino Data Lab monitoring config. Required when type = \"domino\". Builds the DOMINO_* runtime env vars automatically."
  default     = null
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

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  description = "VPC configuration for the canary Lambda (required to reach internal/private endpoints). Leave null to run in the default Synthetics environment."
  default     = null
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

variable "timeout_in_seconds" {
  type        = number
  description = "Canary execution timeout in seconds. Must exceed the workspace poll timeout (DOMINO_WORKSPACE_POLL_TIMEOUT_SECONDS, default 240) plus start time, or the Lambda is killed mid-poll."
  default     = 600
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
