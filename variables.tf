variable "artifact_bucket_name" {
  type        = string
  description = "Name of the shared S3 bucket that stores canary run artifacts."
  default     = "synthcanlogz1231233"
}

variable "cloudwatch_map" {
  type = map(object({
    name                = string
    sns_topic_email     = string
    type                = optional(string, "browser") # "browser" | "api" | "domino"
    endpoint            = optional(string)            # required for "api" (URL) and "domino" (host base URL)
    method              = optional(string, "GET")
    start_canary        = optional(bool, true) # set false to create but not run (e.g. placeholder targets)
    schedule_expression = optional(string)     # per-canary override; defaults to rate(5 minutes)
    # Optional API response assertions (type == "api"). Any unset check is skipped.
    expected_status = optional(number)      # assert an exact status code instead of any 2xx
    max_latency_ms  = optional(number)      # fail if the response is slower than this (also used by "domino")
    body_contains   = optional(string)      # assert this substring is present in the body
    json_assertions = optional(map(string)) # assert dotted JSON paths equal these values
    request_headers = optional(map(string)) # request headers (e.g. Authorization) — see security note
    request_body    = optional(string)      # raw request body for POST/PUT
    # Domino Data Lab options (type == "domino").
    project_id    = optional(string) # target Domino project id
    domino_action = optional(string) # "job" | "workspace" (default "job")
    run_command   = optional(string) # job run command (default "main.py")
    cleanup       = optional(bool)   # stop the started job/workspace afterward (default true)
    # API key (X-Domino-Api-Key): prefer Secrets Manager over the plaintext fallback.
    api_key_secret_arn      = optional(string) # Secrets Manager secret ARN read at runtime (preferred)
    api_key_secret_json_key = optional(string) # if the secret is JSON, the key holding the api key
    api_key                 = optional(string) # plaintext fallback — avoid for real secrets
    # Run this canary inside the AFT shared VPC (internal/private endpoints).
    vpc_enabled = optional(bool, false)
  }))
  # No default: the canary configs live in ../cue/*.cue and are compiled to
  # cloudwatch_map.auto.tfvars.json in CI (see .github/workflows/deploy_and_run.yml)
  # before `terraform plan`/`apply` run. The validation blocks below stay as a
  # second, independent check in case that file is ever hand-edited.

  validation {
    condition     = alltrue([for c in var.cloudwatch_map : contains(["browser", "api", "domino"], c.type)])
    error_message = "Each canary's type must be one of \"browser\", \"api\", or \"domino\"."
  }

  validation {
    condition     = alltrue([for c in var.cloudwatch_map : c.type != "api" || (c.endpoint != null && c.endpoint != "")])
    error_message = "Each canary with type = \"api\" must set a non-empty endpoint."
  }

  validation {
    condition     = alltrue([for c in var.cloudwatch_map : c.type != "domino" || (c.endpoint != null && c.endpoint != "" && c.project_id != null && (c.api_key_secret_arn != null || c.api_key != null))])
    error_message = "Each canary with type = \"domino\" must set endpoint (host), project_id, and either api_key_secret_arn or api_key."
  }
}
