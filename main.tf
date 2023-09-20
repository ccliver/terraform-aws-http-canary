locals {
  name = "health-check-${var.app_name}"
}

resource "aws_sns_topic" "health_check" {
  display_name = local.name
  name         = local.name
}

resource "aws_sns_topic_subscription" "health_check" {
  topic_arn              = aws_sns_topic.health_check.arn
  protocol               = var.sns_subscription_protocol
  endpoint_auto_confirms = true
  endpoint               = var.alert_endpoint
}

resource "aws_cloudwatch_metric_alarm" "health_check" {
  alarm_name          = local.name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = local.name
  namespace           = var.cloudwatch_metric_namespace
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.health_check.arn]
  ok_actions          = [aws_sns_topic.health_check.arn]
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
  description = "Grant Cloudwatch access for http-health_check-${var.app_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
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

resource "null_resource" "build_package" {
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module}/src
      rm -rf dist package
      poetry build
      poetry run pip install -t package dist/*.whl
      cd package
    EOF
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src/package/"
  output_path = "${path.module}/package.zip"
  excludes    = toset(["*.pyc"])

  depends_on = [null_resource.build_package]
}

resource "aws_lambda_function" "health_check" {
  filename         = "${path.module}/package.zip"
  function_name    = local.name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "http_check.main.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.11"

  environment {
    variables = {
      HEALTH_CHECK_ENDPOINT   = var.health_check_endpoint
      METRIC_NAME             = local.name
      METRIC_NAMESPACE        = var.cloudwatch_metric_namespace
      ACCEPTABLE_RETURN_CODES = join(",", var.acceptable_return_codes)
    }
  }
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check.arn
}

resource "aws_cloudwatch_event_rule" "health_check" {
  name                = local.name
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "health_check" {
  target_id = local.name
  rule      = aws_cloudwatch_event_rule.health_check.name
  arn       = aws_lambda_function.health_check.arn
}
