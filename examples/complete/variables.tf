variable "health_check_endpoint" {
  type        = string
  description = "The HTTP endpoint to check."
}

variable "alert_endpoint" {
  type        = string
  description = "The HTTP alert endpoint or email address."
}

variable "sns_subscription_protocol" {
  type        = string
  description = "The SNS subscription protocol (email or http)."
}

variable "cloudwatch_metric_namespace" {
  type        = string
  description = "The namespace to put the Cloudwatch metric under."
  default     = null
}
