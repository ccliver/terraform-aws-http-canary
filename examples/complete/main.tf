provider "aws" {
  region = "us-east-2"
}

module "healthcheck" {
  source = "../.."

  app_name             = "testapp"
  healthcheck_endpoint = "https://example.com"
  alert_endpoint       = "https://example.com"
}
