resource "aws_sns_topic" "healthcheck" {
  display_name = "http-healthcheck-${var.app_name}"
  name         = "http-healthcheck-${var.app_name}"
}

resource "aws_sns_topic_subscription" "healthcheck" {
  topic_arn              = aws_sns_topic.healthcheck.arn
  protocol               = "https"
  endpoint_auto_confirms = true
  endpoint               = var.alert_endpoint
}

resource "aws_cloudwatch_metric_alarm" "healthcheck" {
  alarm_name          = "http-healthcheck-${var.app_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "http-healthcheck-${var.app_name}"
  namespace           = "http-healthcheck-${var.app_name}"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.healthcheck.arn]
  ok_actions          = [aws_sns_topic.healthcheck.arn]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "http-healthcheck-${var.app_name}"

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
  name        = "http-healthcheck-${var.app_name}"
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
  name       = "http-healthcheck-${var.app_name}"
  roles      = [aws_iam_role.iam_for_lambda.name]
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/http_check"
  output_path = "${path.module}/http_check.zip"
}

resource "aws_lambda_function" "healthcheck" {
  filename         = "http_check.zip"
  function_name    = "http-healthcheck-${var.app_name}"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "healthcheck"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      HTTP_HEALTHCHECK_ENDPOINT = var.healthcheck_endpoint
      APP_NAME                  = var.app_name
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
  name                = "http-healthcheck-${var.app_name}"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "healthcheck" {
  target_id = "http-healthcheck-${var.app_name}"
  rule      = aws_cloudwatch_event_rule.healthcheck.name
  arn       = aws_lambda_function.healthcheck.arn
}
