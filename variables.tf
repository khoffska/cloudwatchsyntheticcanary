variable "cloudwatch_map" {
  type = map(object({
    name            = string
    sns_topic_email = string
    zip_file        = string
  }))
  default = {
    "google" = {
      name            = "google"
      sns_topic_email = "hoffstad@gmail.com"
      zip_file        = "src/google.zip"
    },
    "youtube" = {
      name            = "youtube"
      sns_topic_email = "discwat@gmail.com"
      zip_file        = "src/youtube.zip"
    }
  }
}
