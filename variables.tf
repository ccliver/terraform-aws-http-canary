variable "app_name" {
  type        = string
  description = "The name of the app you're testing. This will be used to name AWS resources so it should be unique."
}

variable "healthcheck_endpoint" {
  type        = string
  description = "The HTTP endpoint to check."
}

variable "alert_endpoint" {
  type        = string
  description = "The HTTP alert endpoint."
}

variable "acceptable_return_codes" {
  type        = list(string)
  description = "List of HTTP return codes indicating the health check was a success."
  default     = ["200"]
}
