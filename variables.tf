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
  }))
  default = {
    "google" = {
      name            = "google"
      sns_topic_email = "alerts-primary@example.com"
    },
    "youtube" = {
      name            = "youtube"
      sns_topic_email = "alerts-secondary@example.com"
    },
    "httpbin-api" = {
      name            = "httpbin-api"
      sns_topic_email = "alerts-primary@example.com"
      type            = "api"
      endpoint        = "https://httpbin.org/status/200"
      expected_status = 200
      max_latency_ms  = 3000
    },
    "httpbin-json" = {
      name            = "httpbin-json"
      sns_topic_email = "alerts-primary@example.com"
      type            = "api"
      endpoint        = "https://httpbin.org/json"
      expected_status = 200
      max_latency_ms  = 3000
      body_contains   = "slideshow"
      json_assertions = {
        "slideshow.title" = "Sample Slide Show"
      }
    },
    # Domino Data Lab canaries — placeholders, disabled until a real deployment
    # URL + API key are available. Flip start_canary = true once set. They launch
    # compute, so keep the schedule infrequent.
    "domino-start-job" = {
      name                = "domino-start-job"
      sns_topic_email     = "alerts-primary@example.com"
      type                = "domino"
      endpoint            = "https://REPLACE-ME.domino.example.com" # Domino host, no trailing path
      api_key_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:domino/api-key-REPLACE"
      project_id          = "REPLACE_WITH_PROJECT_ID"
      domino_action       = "job"
      run_command         = "main.py"
      max_latency_ms      = 10000
      start_canary        = false
      schedule_expression = "rate(1 hour)"
    },
    "domino-start-workspace" = {
      name                = "domino-start-workspace"
      sns_topic_email     = "alerts-primary@example.com"
      type                = "domino"
      endpoint            = "https://REPLACE-ME.domino.example.com"
      api_key_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:domino/api-key-REPLACE"
      project_id          = "REPLACE_WITH_PROJECT_ID"
      domino_action       = "workspace"
      max_latency_ms      = 15000
      start_canary        = false
      schedule_expression = "rate(1 hour)"
    }
  }

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
