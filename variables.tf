variable "artifact_bucket_name" {
  type        = string
  description = "Name of the shared S3 bucket that stores canary run artifacts."
  default     = "synthcanlogz1231233"
}

variable "cloudwatch_map" {
  type = map(object({
    name            = string
    sns_topic_email = string
    type            = optional(string, "browser") # "browser" | "api"
    endpoint        = optional(string)            # required when type == "api"
    method          = optional(string, "GET")
    # Optional API response assertions (type == "api" only). Any unset check is skipped.
    expected_status = optional(number)      # assert an exact status code instead of any 2xx
    max_latency_ms  = optional(number)      # fail if the response is slower than this
    body_contains   = optional(string)      # assert this substring is present in the body
    json_assertions = optional(map(string)) # assert dotted JSON paths equal these values
    request_headers = optional(map(string)) # request headers (e.g. Authorization) — see security note
    request_body    = optional(string)      # raw request body for POST/PUT
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
    }
  }

  validation {
    condition     = alltrue([for c in var.cloudwatch_map : contains(["browser", "api"], c.type)])
    error_message = "Each canary's type must be either \"browser\" or \"api\"."
  }

  validation {
    condition     = alltrue([for c in var.cloudwatch_map : c.type != "api" || (c.endpoint != null && c.endpoint != "")])
    error_message = "Each canary with type = \"api\" must set a non-empty endpoint."
  }
}
