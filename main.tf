locals {
  name = "health-check-${var.app_name}"
}

resource "aws_sns_topic" "healthcheck" {
  display_name = local.name
  name         = local.name
}

resource "aws_sns_topic_subscription" "healthcheck" {
  topic_arn              = aws_sns_topic.healthcheck.arn
  protocol               = "https"
  endpoint_auto_confirms = true
  endpoint               = var.alert_endpoint
}

resource "aws_cloudwatch_metric_alarm" "healthcheck" {
  alarm_name          = local.name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = local.name
  namespace           = local.name
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.healthcheck.arn]
  ok_actions          = [aws_sns_topic.healthcheck.arn]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = local.name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cloudwatch_access" {
  name        = local.name
  path        = "/"
  description = "Grant Cloudwatch access for http-healthcheck-${var.app_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "cloudwatch_access" {
  name       = local.name
  roles      = [aws_iam_role.iam_for_lambda.name]
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/http_check"
  output_path = "${path.module}/http_check.zip"
}

data "aws_region" "current" {}

resource "aws_lambda_function" "healthcheck" {
  filename         = "http_check.zip"
  function_name    = local.name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "healthcheck"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      AWS_REGION              = data.aws_region.current.name
      HEALTH_CHECK_ENDPOINT   = var.healthcheck_endpoint
      METRIC_NAME             = local.name
      ACCEPTABLE_RETURN_CODES = join(",", var.acceptable_return_codes)
    }
  }
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healthcheck.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.healthcheck.arn
}

resource "aws_cloudwatch_event_rule" "healthcheck" {
  name                = local.name
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "healthcheck" {
  target_id = local.name
  rule      = aws_cloudwatch_event_rule.healthcheck.name
  arn       = aws_lambda_function.healthcheck.arn
}
