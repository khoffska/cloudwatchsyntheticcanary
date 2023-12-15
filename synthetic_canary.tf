
#not in loop
resource "aws_s3_bucket" "canary-output-bucket" {
  bucket        = "synthcanlogz123123"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}
resource "aws_s3_bucket_ownership_controls" "canary-output-bucket" {
  bucket = aws_s3_bucket.canary-output-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "canary-output-bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.canary-output-bucket]

  bucket = aws_s3_bucket.canary-output-bucket.id
  acl    = "private"
}
#not in loop
resource "aws_iam_role" "my-cloudwatch-syn-role" {
  name               = "my-cloudwatch-syn-role"
  description        = "Role used to provide permissions for the canary to run."
  managed_policy_arns = [aws_iam_policy.policy_one.arn,aws_iam_policy.policy_two.arn]
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "Service": "lambda.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
          }
      ]
    }
    EOF
}
resource "aws_iam_policy" "policy_one" {
  name = "policy-618033"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::synthcanlogz123123"
      },
    ]
  })
}
resource "aws_iam_policy" "policy_two" {
  name = "policy-6180332"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.canary-output-bucket.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "${aws_s3_bucket.canary-output-bucket.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "xray:PutTraceSegments"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": "cloudwatch:PutMetricData",
      "Condition": {
        "StringEquals": {
          "cloudwatch:namespace": "CloudWatchSynthetics"
        }
      }
    }
  ]
}
EOT
}


resource "aws_synthetics_canary" "my-api-canary" {
  for_each             = var.cloudwatch_map
  name                 = each.value.name
  artifact_s3_location = "s3://${aws_s3_bucket.canary-output-bucket.bucket}/"
  execution_role_arn   = aws_iam_role.my-cloudwatch-syn-role.arn
  zip_file             = each.value.zip_file
  handler              = "${each.value.name}.handler"
  runtime_version      = "syn-python-selenium-2.0"
  delete_lambda        = true
  schedule {
    expression = "rate(5 minutes)"
  }
  start_canary = true
}

resource "aws_cloudwatch_metric_alarm" "my-api-canary-alarm" {
  for_each                  = var.cloudwatch_map
  alarm_name                = each.value.name
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "SuccessPercent"
  namespace                 = "CloudWatchSynthetics"
  threshold                 = "100"
  statistic                 = "Average"
  period                    = "300"
  alarm_description         = "This alarm fires if the canary fails"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.my-topic[each.key].arn]

  dimensions = {
    CanaryName = each.value.name
  }
}



resource "aws_sns_topic" "my-topic" {
  for_each = var.cloudwatch_map
  name     = each.value.name
}

resource "aws_sns_topic_subscription" "my-topic-sub" {
  for_each  = var.cloudwatch_map
  topic_arn = aws_sns_topic.my-topic[each.key].arn
  protocol  = "email"
  endpoint  = each.value.sns_topic_email

  depends_on = [
    aws_sns_topic.my-topic
  ]
}