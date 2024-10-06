variable "cloudwatch_map" {
  type = map(object({
    name            = string
    sns_topic_email = string
    zip_file        = string
  }))
  default = {
    "google" = {
      name            = "google"
      sns_topic_email = "alerts-primary@example.com"
      zip_file        = "src/google.zip"
    },
    "youtube" = {
      name            = "youtube"
      sns_topic_email = "alerts-secondary@example.com"
      zip_file        = "src/youtube.zip"
    }
  }
}
