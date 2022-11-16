provider "aws" {
  region = "us-east-2"
}

module "healthcheck" {
  source = "../.."

  app_name                    = "testapp"
  cloudwatch_metric_namespace = var.cloudwatch_metric_namespace
  health_check_endpoint       = var.health_check_endpoint
  alert_endpoint              = var.alert_endpoint
  sns_subscription_protocol   = var.sns_subscription_protocol
}
