variable "endpoint" {
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
