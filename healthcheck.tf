provider "aws" {
  region = "us-west-2"
}

module "healthcheck" {
  source = "./http-healthcheck"

  app_name             = "testapp"
  region               = "us-west-2"
  healthcheck_endpoint = "https://example.com"
  alert_endpoint       = "https://example.com"
}
