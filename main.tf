data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region
  name   = "${var.app_name}-canary"
  dimensions = join(",", [
    for key, value in var.cloudwatch_dimensions :
    "${key}=${value}"
  ])
}

# trivy:ignore:AVD-AWS-0095
resource "aws_sns_topic" "canary" {
  display_name = local.name
  name         = local.name
}

resource "aws_sns_topic_subscription" "canary" {
  topic_arn              = aws_sns_topic.canary.arn
  protocol               = var.sns_subscription_protocol
  endpoint_auto_confirms = true
  endpoint               = var.alert_endpoint
}

resource "aws_cloudwatch_metric_alarm" "canary" {
  alarm_name          = local.name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = var.cloudwatch_metric_name
  namespace           = var.cloudwatch_metric_namespace
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.canary.arn]
  ok_actions          = [aws_sns_topic.canary.arn]
  treat_missing_data  = "notBreaching"
  dimensions          = var.cloudwatch_dimensions
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
  description = "Grant Cloudwatch access for ${var.app_name}-canary"

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

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
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

resource "aws_lambda_function" "canary" {
  filename         = "${path.module}/package.zip"
  function_name    = local.name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "canary.main.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.13"
  timeout          = var.lambda_timeout

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      REGION            = local.region
      ENDPOINT          = var.endpoint
      METRIC_NAMESPACE  = var.cloudwatch_metric_namespace
      METRIC_NAME       = try(var.cloudwatch_metric_name, "${var.app_name}Status")
      METRIC_DIMENSIONS = local.dimensions
      OK_RETURN_CODES   = join(",", var.ok_return_codes)
      REQUEST_TIMEOUT   = var.request_timeout
      TOPIC_ARN         = aws_sns_topic.canary.arn
    }
  }
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.canary.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.canary.arn
}

resource "aws_cloudwatch_event_rule" "canary" {
  name                = local.name
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "canary" {
  target_id = local.name
  rule      = aws_cloudwatch_event_rule.canary.name
  arn       = aws_lambda_function.canary.arn
}
