variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}