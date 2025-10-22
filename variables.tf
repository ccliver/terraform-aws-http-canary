variable "app_name" {
  type        = string
  description = "The name of the app you're testing. This will be used to name AWS resources so it should be unique."
}

variable "endpoint" {
  type        = string
  description = "The HTTP endpoint to check."
}

variable "alert_endpoint" {
  type        = string
  description = "The HTTP alert endpoint or email address."
}

variable "ok_return_codes" {
  type        = list(number)
  description = "List of HTTP return codes indicating the health check was a success."
  default     = [200]
}

variable "cloudwatch_metric_namespace" {
  type        = string
  description = "The namespace to put the CloudWatch metric under."
}

variable "cloudwatch_metric_name" {
  type        = string
  description = "The name of the CloudWatch metric."
  default     = null
}

variable "cloudwatch_dimensions" {
  type        = map(string)
  description = "A map of key=value pairs to use as dimensions for the CloudWatch metric."
  default     = {}
}

variable "sns_subscription_protocol" {
  type        = string
  description = "The SNS subscription protocol (email or http)."

  validation {
    condition     = can(regex("^email$|^http$", var.sns_subscription_protocol))
    error_message = "Valid values are email or http."
  }
}

variable "schedule_expression" {
  type        = string
  description = "The [scheduling expression](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html). For example, cron(0 20 * * ? *) or rate(5 minutes)."
  default     = "rate(1 minute)"
}

variable "request_timeout" {
  type        = string
  description = "Timeout in seconds for GET request to endpoitn."
  default     = 5
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds."
  default     = 5
}
