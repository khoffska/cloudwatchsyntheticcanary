variable "cloudwatch_map" {
  type = map(object({
    name            = string
    sns_topic_email = string
    zip_file        = string
  }))
  default = {
    "domino" = {
      name            = "domino"
      sns_topic_email = "hoffstad@gmail.com"
      zip_file        = "src/domino.zip"
    },
    "aetion" = {
      name            = "aetion"
      sns_topic_email = "discwat@gmail.com"
      zip_file        = "src/aetion.zip"
    },
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