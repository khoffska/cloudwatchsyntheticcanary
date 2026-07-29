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
