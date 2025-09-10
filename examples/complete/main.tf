provider "aws" {
  region = "us-east-1"
}

module "healthcheck" {
  source = "../.."

  app_name                    = "testapp"
  cloudwatch_metric_namespace = "ExampleComplete"
  cloudwatch_metric_name      = "ExampleCompleteHTTPStatus"
  cloudwatch_dimensions = {
    AppName     = "testapp"
    Environment = "Testing"
  }
  endpoint                  = var.endpoint
  alert_endpoint            = var.alert_endpoint
  sns_subscription_protocol = var.sns_subscription_protocol
  request_timeout           = 5
  #schedule_expression         = "rate(5 minutes)"
}
