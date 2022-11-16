variable "app_name" {
  type        = string
  description = "The name of the app you're testing. This will be used to name AWS resources so it should be unique."
}

variable "health_check_endpoint" {
  type        = string
  description = "The HTTP endpoint to check."
}

variable "alert_endpoint" {
  type        = string
  description = "The HTTP alert endpoint or email address."
}

variable "acceptable_return_codes" {
  type        = list(string)
  description = "List of HTTP return codes indicating the health check was a success."
  default     = ["200"]
}

variable "cloudwatch_metric_namespace" {
  type        = string
  description = "The namespace to put the Cloudwatch metric under."
  default     = null
}

variable "sns_subscription_protocol" {
  type        = string
  description = "The SNS subscription protocol (email or http)."

  validation {
    condition     = can(regex("^email$|^http$", var.sns_subscription_protocol))
    error_message = "Valid values are email or http."
  }
}
