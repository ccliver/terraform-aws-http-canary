variable "app_name" {
  description = "The name of the app you're testing. This will be used to name AWS resources so it should be unique."
}

variable "region" {
  description = "The AWS region to deploy the check to."
}

variable "healthcheck_endpoint" {
  description = "The endpoint to check."
}

variable "alert_endpoint" {
  description = "The alert endpoint (VictorOps, Pagerduty, etc)."
}
